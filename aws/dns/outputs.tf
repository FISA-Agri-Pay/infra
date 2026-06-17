output "hosted_zone_id" {
  description = "Route 53 hosted zone ID."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Set these NS records at the example.com registrar."
  value       = aws_route53_zone.this.name_servers
}

output "acm_certificate_arn" {
  description = "Validated ACM certificate ARN (pass to the web-edge module)."
  value       = aws_acm_certificate_validation.this.certificate_arn
}
