variable "region" {
  description = "AWS region for the recorded S3 buckets."
  type        = string
  default     = "ap-northeast-2"
}

variable "account_id" {
  description = "AWS account ID used to compose globally-unique bucket names. Templated placeholder; replace with the console value if names must resolve."
  type        = string
  default     = "000000000000"
}

variable "secure_docs_kms_key_arn" {
  description = "Customer-managed KMS key ARN used for the secure credit document bucket. Templated placeholder; the real ARN lives in the AWS console / data layer."
  type        = string
  default     = "arn:aws:kms:ap-northeast-2:000000000000:key/EXAMPLE_DOCUMENT_KMS_KEY"
}
