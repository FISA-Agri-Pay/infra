variable "domain_name" {
  description = "Apex domain for the Route 53 hosted zone (e.g. kongkongpatpat.shop)."
  type        = string
}

variable "create_www_record" {
  description = "Create a www.<domain> alias to the CloudFront distribution."
  type        = bool
  default     = true
}
