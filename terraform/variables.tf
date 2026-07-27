variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo dos recursos"
  type        = string
  default     = "fcg"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "fcg-cluster"
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes no EKS"
  type        = string
  default     = "1.33"
}

variable "node_instance_type" {
  description = "Tipo de instância dos nós do EKS (deve ser free-tier-eligible em contas Free Plan)"
  type        = string
  default     = "m7i-flex.large"
}

variable "opensearch_master_user" {
  description = "Usuário master do Amazon OpenSearch (fine-grained access control)"
  type        = string
  default     = "fcg-admin"
}
