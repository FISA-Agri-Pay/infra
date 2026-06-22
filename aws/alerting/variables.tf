variable "region" {
  description = "AWS region for the recorded CloudWatch alerting stack."
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS cluster the alarms originate from. Used as a Lambda env var."
  type        = string
  default     = "kkpp-eks"
}

variable "lambda_package_path" {
  description = "Path to the Lambda deployment package (zip). Templated placeholder; the real function code is not stored in this repo."
  type        = string
  default     = "placeholder/slack-alerts.zip"
}

variable "eks_nodes" {
  description = <<-EOT
    Per-node EKS alarms (NodeNotReady, RootFilesystemAlmostFull) are auto-created
    by the amazon-cloudwatch-observability addon for each worker node. Node names
    and instance IDs are ephemeral, so this list holds templated placeholders only.
  EOT
  type = list(object({
    node_name   = string
    instance_id = string
  }))
  default = [
    { node_name = "ip-0-0-0-0.ap-northeast-2.compute.internal", instance_id = "i-00000000000000000" },
    { node_name = "ip-0-0-0-1.ap-northeast-2.compute.internal", instance_id = "i-00000000000000001" },
  ]
}
