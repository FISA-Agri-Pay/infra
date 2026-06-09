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
  description = "Monitoring namespace."
  type        = string
  default     = "monitoring"
}