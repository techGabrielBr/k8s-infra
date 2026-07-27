# =====================================================================
# Setup da infraestrutura AWS emulada no LocalStack
# Pré-requisitos: LocalStack rodando (docker compose up -d) e AWS CLI.
# =====================================================================

$env:AWS_ACCESS_KEY_ID = "teste"
$env:AWS_SECRET_ACCESS_KEY = "teste"
$env:AWS_DEFAULT_REGION = "us-east-1"

$endpoint = "http://localhost:4566"

# ---------------------------------------------------------------------
# Filas SQS (mensageria entre os microsserviços)
# ---------------------------------------------------------------------
aws --endpoint-url=$endpoint sqs create-queue --queue-name user-created-event
aws --endpoint-url=$endpoint sqs create-queue --queue-name payment-processed-event
aws --endpoint-url=$endpoint sqs create-queue --queue-name payment-processed-catalog

# ---------------------------------------------------------------------
# Lambda de notificações (substitui a antiga NotificationsAPI)
# Executar a partir da pasta Lambdas/NotificationsFunction (onde está o function.zip)
# ---------------------------------------------------------------------
aws --endpoint-url=$endpoint lambda create-function `
    --function-name notifications-function `
    --runtime nodejs20.x `
    --handler index.handler `
    --role arn:aws:iam::000000000000:role/lambda-role `
    --zip-file fileb://../../Lambdas/NotificationsFunction/function.zip

aws --endpoint-url=$endpoint lambda create-event-source-mapping `
    --function-name notifications-function `
    --event-source-arn arn:aws:sqs:us-east-1:000000000000:user-created-event

aws --endpoint-url=$endpoint lambda create-event-source-mapping `
    --function-name notifications-function `
    --event-source-arn arn:aws:sqs:us-east-1:000000000000:payment-processed-event

# ---------------------------------------------------------------------
# Domínio OpenSearch (Busca Avançada do CatalogAPI)
# O primeiro create-domain baixa o binário do OpenSearch — pode demorar
# alguns minutos. Aguarde "Processing: false" no describe-domain.
# ---------------------------------------------------------------------
aws --endpoint-url=$endpoint opensearch create-domain --domain-name fcg-games

Write-Host ""
Write-Host "Aguardando o domínio OpenSearch ficar disponível..."

do {
    Start-Sleep -Seconds 10
    $status = aws --endpoint-url=$endpoint opensearch describe-domain --domain-name fcg-games | ConvertFrom-Json
    Write-Host "  Processing: $($status.DomainStatus.Processing)"
} while ($status.DomainStatus.Processing -eq $true)

Write-Host ""
Write-Host "OpenSearch pronto em: $endpoint/opensearch/us-east-1/fcg-games"
Write-Host "Setup concluído!"
