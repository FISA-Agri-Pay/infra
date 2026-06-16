variable "region" {
  description = "AWS region for regional FinOps support resources."
  type        = string
  default     = "ap-northeast-2"
}

variable "cur_bucket_name" {
  description = "S3 bucket name for Cost and Usage Reports. Leave null to use kkpp-cur-reports-<account-id>."
  type        = string
  default     = null
}

variable "cur_report_name" {
  description = "Cost and Usage Report name."
  type        = string
  default     = "kkpp-cur"
}

variable "cur_s3_prefix" {
  description = "S3 prefix for Cost and Usage Report objects."
  type        = string
  default     = "cur"
}
