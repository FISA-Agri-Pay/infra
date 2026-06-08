variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "Existing EKS cluster name."
  type        = string
  default     = "kkpp-eks"
}

variable "namespace" {
  description = "Existing Kubernetes namespace for monitoring components."
  type        = string
  default     = "monitoring"
}

variable "loki_chart_version" {
  description = "Grafana Loki Helm chart version."
  type        = string
  default     = "6.24.0"
}

variable "common_tags" {
  description = "Common tags for FinOps and resource ownership."
  type        = map(string)

  default = {
    Project     = "kkpp"
    Service     = "observability"
    Component   = "loki"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "dev6"
    CostCenter  = "fisa-dev6"
  }
}