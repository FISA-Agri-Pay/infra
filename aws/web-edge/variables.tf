variable "region" {
  description = "AWS region for the web-edge resources (ALBs, security groups). CloudFront itself is global."
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_id" {
  description = "VPC that hosts the internal ALBs and their security groups."
  type        = string
  default     = "vpc-000657d90c7a6085c"
}

variable "alb_subnet_ids" {
  description = "Private (internal-elb) subnets for the admin-api internal ALB."
  type        = list(string)
  default     = ["subnet-0dc55bbd450ac9f03", "subnet-0fa7830f7ccadd210"]
}

# --- Edge wiring (opt-in). Defaults preserve the current distribution exactly:
# no custom domain, the default CloudFront cert, and no WAF. Populate these from
# the aws/edge + aws/dns module outputs once the ACM cert is ISSUED. ----------

variable "aliases" {
  description = "Custom domain names (CNAMEs) on the distribution, e.g. [\"kongkongpatpat.shop\", \"www.kongkongpatpat.shop\"]."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "us-east-1 ACM certificate ARN for the custom domain. Null keeps the default CloudFront certificate."
  type        = string
  default     = null
}

variable "web_acl_arn" {
  description = "WAFv2 (CLOUDFRONT scope) Web ACL ARN to attach. Null leaves the distribution without WAF."
  type        = string
  default     = null
}
