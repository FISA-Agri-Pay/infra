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
