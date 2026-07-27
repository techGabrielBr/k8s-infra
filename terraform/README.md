# Infraestrutura AWS (Terraform) — Fase 4

Provisiona toda a infraestrutura da FIAP Cloud Games na AWS (`us-east-1`):

| Recurso | Nome | Uso |
|---|---|---|
| VPC | `fcg-vpc` | Rede (2 AZs, subnets públicas, sem NAT p/ reduzir custo) |
| EKS | `fcg-cluster` | Kubernetes gerenciado (2x m7i-flex.large) |
| ECR | `users-api`, `catalog-api`, `payments-api` | Registry privado de imagens |
| SQS | `user-created-event`, `payment-processed-event`, `payment-processed-catalog` | Mensageria |
| Lambda | `notifications-function` | Notificações (trigger nas filas SQS) |
| OpenSearch | `fcg-games` | Busca avançada (t3.small.search, fine-grained access control) |
| Secrets Manager | `fcg/jwt`, `fcg/rabbitmq`, `fcg/opensearch`, `fcg/app-aws-credentials` | Fonte única dos segredos (gerados via `random_password`) |
| IAM | `fcg-ci` | Usuário do GitHub Actions (push ECR + deploy EKS) |
| IAM | `fcg-app` | Usuário das APIs (SQS) — access key vai direto pro Secrets Manager |
| IAM (IRSA) | `fcg-external-secrets` | Role do External Secrets Operator (leitura de `fcg/*`) |

MongoDB, Redis, RabbitMQ, Kong, Prometheus e Grafana continuam rodando **dentro do cluster** (manifests em `Infra/`, `Metrics/`). Os segredos são injetados em runtime pelo **External Secrets Operator** (ver `Infra/external-secrets/README.md`) — nenhuma credencial em código ou YAML.

## 💰 Custo estimado (us-east-1)

~USD 0,45/hora ≈ **USD 11/dia**: EKS control plane (0,10/h) + 2x m7i-flex.large (~0,19/h) + OpenSearch t3.small.search (0,036/h) + EBS/ELB. Em contas Free Plan, esses valores consomem os créditos gratuitos. Secrets Manager: ~USD 0,40/segredo/mês (desprezível). **Rode `terraform destroy` assim que terminar a gravação do vídeo.**

## Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- AWS CLI v2 autenticada (`aws configure`) com um usuário admin
- kubectl e [Helm](https://helm.sh/docs/intro/install/)

## 1. Provisionar

```bash
cd Infra/terraform
terraform init
terraform apply
```

> Sem variáveis: todas as senhas (JWT, RabbitMQ, OpenSearch) são geradas
> automaticamente e armazenadas no Secrets Manager.
> O apply demora ~20-25 min (EKS ~12 min, OpenSearch ~15 min, em paralelo).

Outputs importantes (`terraform output`): `account_id`, `opensearch_endpoint`, `external_secrets_role_arn`, `ecr_repository_urls`.

## 2. Apontar o kubectl para o EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name fcg-cluster
kubectl get nodes
```

## 3. Instalar o External Secrets Operator

Siga `Infra/external-secrets/README.md` (helm install com a role IRSA + `cluster-secret-store.yaml`). Resumo:

```bash
ROLE_ARN=$(terraform output -raw external_secrets_role_arn)
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ROLE_ARN"
kubectl -n external-secrets rollout status deployment/external-secrets
kubectl apply -f ../external-secrets/cluster-secret-store.yaml
```

## 4. Preencher os placeholders (apenas valores NÃO sensíveis)

Nos `k8s/` de UsersAPI, CatalogAPI e PaymentsAPI, substitua:

| Placeholder | Onde | Valor |
|---|---|---|
| `<ACCOUNT_ID>` | configmaps e deployments | output `account_id` |
| `<OPENSEARCH_ENDPOINT>` | configmap do CatalogAPI | output `opensearch_endpoint` |

> Os `secret.yaml` não têm mais nada para preencher: são recursos `ExternalSecret`
> que o ESO resolve sozinho a partir do Secrets Manager.

## 5. Publicar as imagens iniciais no ECR

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker build -t $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/users-api:latest ./UsersAPI
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/users-api:latest
docker build -t $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/catalog-api:latest ./CatalogAPI
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/catalog-api:latest
docker build -t $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/payments-api:latest ./PaymentsAPI
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/payments-api:latest
```

(Depois disso, quem publica imagem é a pipeline.)

## 6. Deploy no cluster

```bash
# Infra in-cluster (os secret.yaml são ExternalSecrets — o ESO cria os secrets reais)
kubectl apply -f Infra/mongo/ -f Infra/redis/ -f Infra/rabbitmq/ -f Infra/gateway/
kubectl apply -f Metrics/prometheus/ -f Metrics/grafana/

# APIs
kubectl apply -f UsersAPI/k8s/
kubectl apply -f CatalogAPI/k8s/
kubectl apply -f PaymentsAPI/k8s/

kubectl get externalsecrets   # READY = True
kubectl get pods
# URL pública (Load Balancer do Kong):
kubectl get svc kong -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 7. Configurar o CI/CD (GitHub Actions)

Gere a access key do usuário de CI:

```bash
aws iam create-access-key --user-name fcg-ci
```

Em **cada** repositório (UsersAPI, CatalogAPI, PaymentsAPI) → *Settings → Secrets and variables → Actions*:

- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` → a key do `fcg-ci`

Pipeline: Build & Test → imagem Docker (tag = SHA + `latest`) → Trivy scan → push ECR → `kubectl set image` no EKS (rolling update, sem downtime). Perfeito para o **Live Deploy** do vídeo.

## 8. Popular a busca (OpenSearch)

Com o CatalogAPI no ar, autentique-se como Admin e chame `POST /games/reindex`.
Busca com fuzzy + relevância: `GET /games/search?q=<termo>` (funciona até com erro de digitação, ex.: `zeldda`).

Para consultar o OpenSearch direto (Dashboards ou curl), pegue a senha master:

```bash
aws secretsmanager get-secret-value --secret-id fcg/opensearch --query SecretString --output text
```

## 9. Destruir tudo (IMPORTANTE)

```bash
# Primeiro remova services LoadBalancer (ELBs criados fora do Terraform)
kubectl delete svc kong grafana

cd Infra/terraform
terraform destroy
```

## Desenvolvimento local

O LocalStack continua funcionando para dev local (`Infra/localstack/`): as APIs detectam a env `AWS_SERVICE_URL` — se presente usam LocalStack, se ausente usam a AWS real com a cadeia padrão de credenciais.
