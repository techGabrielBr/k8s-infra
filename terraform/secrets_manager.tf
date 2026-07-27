resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

resource "random_password" "rabbitmq" {
  length  = 24
  special = false
}

# Atende à política de complexidade do master user do OpenSearch
resource "random_password" "opensearch_master" {
  length           = 16
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#$%&*()-_=+"
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

locals {
  secrets = {
    "jwt" = {
      JWT_SECRET = random_password.jwt_secret.result
    }
    "rabbitmq" = {
      username = "fcg"
      password = random_password.rabbitmq.result
    }
    "opensearch" = {
      username = var.opensearch_master_user
      password = random_password.opensearch_master.result
    }
    "app-aws-credentials" = {
      AWS_ACCESS_KEY_ID     = aws_iam_access_key.app.id
      AWS_SECRET_ACCESS_KEY = aws_iam_access_key.app.secret
    }
  }
}

resource "aws_secretsmanager_secret" "secrets" {
  for_each = local.secrets

  name = "${var.project_name}/${each.key}"

  # Exclusão imediata no destroy, permitindo recriar com o mesmo nome
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "secrets" {
  for_each = local.secrets

  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = jsonencode(each.value)
}
