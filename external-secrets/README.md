# External Secrets Operator + AWS Secrets Manager

Os segredos do projeto vivem no **AWS Secrets Manager** (criados pelo Terraform em
`Infra/terraform/secrets_manager.tf`) e são sincronizados para dentro do cluster
pelo **External Secrets Operator (ESO)** — nenhum valor sensível existe em YAML
ou no código.

```text
AWS Secrets Manager (fcg/*)
        │  leitura via role IRSA (OIDC, sem chave estática)
        ▼
External Secrets Operator (namespace external-secrets)
        │  reconcilia recursos ExternalSecret
        ▼
Secrets nativos do Kubernetes (users-api-secret, catalog-api-secret, ...)
        │  envFrom / secretKeyRef
        ▼
Pods das APIs, RabbitMQ e Kong
```

## Segredos no Secrets Manager

| Segredo | Conteúdo | Consumido por |
|---|---|---|
| `fcg/jwt` | `JWT_SECRET` | UsersAPI, CatalogAPI, Kong |
| `fcg/rabbitmq` | `username`, `password` | RabbitMQ, CatalogAPI, PaymentsAPI |
| `fcg/opensearch` | `username`, `password` | CatalogAPI |
| `fcg/app-aws-credentials` | access key do usuário `fcg-app` (SQS) | UsersAPI, CatalogAPI, PaymentsAPI |

Todos os valores são **gerados pelo Terraform** (`random_password`) — ninguém digita senha.

## Instalação (após o `terraform apply`)

```bash
# 1. Role IRSA criada pelo Terraform
ROLE_ARN=$(cd ../terraform && terraform output -raw external_secrets_role_arn)

# 2. Instalar o operator via Helm, anotando o service account com a role
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ROLE_ARN"

# 3. Aguardar o operator subir
kubectl -n external-secrets rollout status deployment/external-secrets

# 4. Conectar ao Secrets Manager
kubectl apply -f cluster-secret-store.yaml
```

Depois disso, os `secret.yaml` de cada projeto (que agora são recursos
`ExternalSecret`) criam os Secrets do K8s automaticamente ao serem aplicados.

## Verificando

```bash
kubectl get clustersecretstore          # STATUS deve ser Valid
kubectl get externalsecrets -A          # READY deve ser True
kubectl get secrets                     # secrets nativos criados pelo ESO

# Ver um valor (ex.: senha do OpenSearch, para testar a busca manualmente)
aws secretsmanager get-secret-value --secret-id fcg/opensearch --query SecretString --output text
```

## Rotação

Como o `refreshInterval` dos ExternalSecrets é `1h`, alterar um valor no
Secrets Manager atualiza os Secrets do cluster em até 1 hora (ou imediatamente
com `kubectl annotate externalsecret <nome> force-sync=$(date +%s)`).
