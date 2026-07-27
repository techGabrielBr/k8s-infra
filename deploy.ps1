$ErrorActionPreference = "Stop"
$region = "us-east-1"

# ----------------------------------------------------------------------------
Write-Host "==> [1/4] Lendo outputs do Terraform..." -ForegroundColor Cyan
# ----------------------------------------------------------------------------
Push-Location "$PSScriptRoot/Infra/terraform"
try {
    $accountId   = terraform output -raw account_id
    $osEndpoint  = terraform output -raw opensearch_endpoint
    $roleArn     = terraform output -raw external_secrets_role_arn
    $clusterName = terraform output -raw cluster_name
}
finally {
    Pop-Location
}
Write-Host "    Account: $accountId | Cluster: $clusterName"
Write-Host "    OpenSearch: $osEndpoint"

# ----------------------------------------------------------------------------
Write-Host "==> [2/4] Configurando kubeconfig..." -ForegroundColor Cyan
# ----------------------------------------------------------------------------
aws eks update-kubeconfig --region $region --name $clusterName | Out-Null
kubectl get nodes

kubectl patch storageclass gp2 -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}' | Out-Null
Write-Host "    StorageClass gp2 marcada como default"

# ----------------------------------------------------------------------------
Write-Host "==> [3/4] Instalando External Secrets Operator..." -ForegroundColor Cyan
# ----------------------------------------------------------------------------
helm repo add external-secrets https://charts.external-secrets.io 2>$null
helm repo update | Out-Null

helm upgrade --install external-secrets external-secrets/external-secrets `
    --namespace external-secrets --create-namespace `
    --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$roleArn" `
    --wait

kubectl apply -f "$PSScriptRoot/Infra/external-secrets/cluster-secret-store.yaml"

# ----------------------------------------------------------------------------
Write-Host "==> [4/4] Aplicando manifests (placeholders resolvidos em memória)..." -ForegroundColor Cyan
# ----------------------------------------------------------------------------
function Apply-Manifests([string[]] $dirs) {
    foreach ($dir in $dirs) {
        Get-ChildItem "$PSScriptRoot/$dir" -Filter *.yaml | ForEach-Object {
            Write-Host "    kubectl apply -f $dir/$($_.Name)"
            (Get-Content $_.FullName -Raw) `
                -replace '<ACCOUNT_ID>', $accountId `
                -replace '<OPENSEARCH_ENDPOINT>', $osEndpoint |
                kubectl apply -f -
        }
    }
}

Apply-Manifests @(
    "Infra/mongo", "Infra/redis", "Infra/rabbitmq", "Infra/gateway",
    "Metrics/prometheus", "Metrics/grafana"
)

Apply-Manifests @("UsersAPI/k8s", "CatalogAPI/k8s", "PaymentsAPI/k8s")

# ----------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Verificação final" -ForegroundColor Green
# ----------------------------------------------------------------------------
kubectl get externalsecrets
kubectl get pods

$kongUrl = kubectl get svc kong -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
if ($kongUrl) {
    Write-Host ""
    Write-Host "URL pública da aplicação (Kong): http://$kongUrl" -ForegroundColor Green
    Write-Host "(o ELB pode levar ~2 min para responder após a criação)"
}
