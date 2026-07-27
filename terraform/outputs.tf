output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Comando para apontar o kubectl para o cluster EKS"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_urls" {
  value = { for name, repo in aws_ecr_repository.apis : name => repo.repository_url }
}

output "sqs_queue_urls" {
  value = { for name, queue in aws_sqs_queue.queues : name => queue.url }
}

output "sqs_base_url" {
  description = "Valor para QUEUE_SQS_BASE_URL nos ConfigMaps"
  value       = "https://sqs.${var.region}.amazonaws.com/${data.aws_caller_identity.current.account_id}/"
}

output "opensearch_endpoint" {
  description = "Valor para OPENSEARCH_URL nos ConfigMaps (prefixar com https://)"
  value       = "https://${aws_opensearch_domain.games.endpoint}"
}

output "opensearch_dashboard" {
  value = "https://${aws_opensearch_domain.games.endpoint}/_dashboards"
}

output "ci_user_name" {
  description = "Usuário IAM do CI (GitHub Actions) — gere a access key com: aws iam create-access-key --user-name <este usuário>"
  value       = aws_iam_user.ci.name
}

output "app_user_name" {
  description = "Usuário IAM das APIs (SQS) — access key gerada automaticamente e armazenada no Secrets Manager (fcg/app-aws-credentials)"
  value       = aws_iam_user.app.name
}

output "external_secrets_role_arn" {
  description = "Role IRSA do External Secrets Operator — usar na instalação via Helm"
  value       = module.external_secrets_irsa.iam_role_arn
}

output "secrets_manager_secrets" {
  description = "Segredos criados no AWS Secrets Manager"
  value       = [for s in aws_secretsmanager_secret.secrets : s.name]
}
