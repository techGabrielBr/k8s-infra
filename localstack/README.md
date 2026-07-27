# LocalStack — Infraestrutura AWS emulada (apenas desenvolvimento local)

> ⚠️ O ambiente **de produção roda na AWS real** — ver `Infra/terraform/README.md`.
> O LocalStack fica como opção de desenvolvimento local sem custo: as APIs detectam
> a variável `AWS_SERVICE_URL` (presente = LocalStack, ausente = AWS real).

O LocalStack emula os serviços AWS usados pela plataforma FCG:

| Serviço AWS | Uso no projeto |
|---|---|
| SQS | Mensageria: `user-created-event`, `payment-processed-event`, `payment-processed-catalog` |
| Lambda | `notifications-function` (substitui a antiga NotificationsAPI) |
| OpenSearch | Busca avançada do CatalogAPI (índice `games`, fuzzy search + relevância) |

## Subindo o LocalStack

```bash
cd Infra/localstack
docker compose up -d
```

> `OPENSEARCH_ENDPOINT_STRATEGY=path` é obrigatório: expõe o domínio OpenSearch
> em `http://localhost:4566/opensearch/us-east-1/fcg-games`, acessível pelos pods
> do Kubernetes via `host.docker.internal:4566`.

## Criando os recursos

```powershell
cd Infra/localstack
./setup.ps1
```

O script cria as filas SQS, a Lambda de notificações (com os event source mappings)
e o domínio OpenSearch `fcg-games`. Na primeira execução, o LocalStack baixa o
binário do OpenSearch — aguarde o script informar que o domínio ficou pronto.

## Verificando

```bash
# Filas
aws --endpoint-url=http://localhost:4566 sqs list-queues

# Lambda
aws --endpoint-url=http://localhost:4566 lambda list-functions

# OpenSearch (Processing deve ser false)
aws --endpoint-url=http://localhost:4566 opensearch describe-domain --domain-name fcg-games

# Consulta direta ao índice de games
curl "http://localhost:4566/opensearch/us-east-1/fcg-games/games/_search?q=zelda"
```

## Endpoints usados pelas APIs (via K8s ConfigMaps)

| Variável | Valor |
|---|---|
| `AWS_SERVICE_URL` | `http://host.docker.internal:4566` |
| `QUEUE_SQS_BASE_URL` | `http://host.docker.internal:4566/000000000000/` |
| `QUEUE_SQS_URL` (Catalog) | `http://host.docker.internal:4566/000000000000/payment-processed-catalog` |
| `OPENSEARCH_URL` (Catalog) | `http://host.docker.internal:4566/opensearch/us-east-1/fcg-games` |

As credenciais (`AWS_USER` / `AWS_PASSWORD`) são injetadas via Kubernetes Secrets —
o LocalStack aceita qualquer valor.

## Populando o índice de busca

Após subir o CatalogAPI, indexe os jogos já existentes no MongoDB (endpoint Admin):

```
POST /games/reindex
```

Novos jogos (`POST /games`) e edições (`PUT /games/{id}`) são indexados
automaticamente. A busca fica em:

```
GET /games/search?q=<termo>
```

Suporta fuzzy search (tolerância a erros de digitação) e ordena por relevância (score).
