output "acm_certificate_arn" {
  description = "ARN of the us-east-1 ACM certificate for CloudFront."
  value       = aws_acm_certificate.this.arn
}

output "acm_domain_validation_options" {
  description = "DNS validation records the aws/dns module must create in Route 53."
  value       = aws_acm_certificate.this.domain_validation_options
}

output "waf_web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL to attach to the CloudFront distribution."
  value       = aws_wafv2_web_acl.cloudfront.arn
}
