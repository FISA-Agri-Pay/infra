variable "domain_name" {
  description = "Primary domain for the ACM certificate (e.g. example.com)."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional names on the ACM certificate (e.g. www.<domain>)."
  type        = list(string)
  default     = []
}

variable "waf_rate_limit" {
  description = "Max requests per 5-minute window per source IP before the rate rule blocks."
  type        = number
  default     = 2000
}
