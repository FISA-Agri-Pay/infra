# --- Admin API internal ALB (owned by this module) -------------------------

output "admin_api_alb_arn" {
  value = aws_lb.admin_api.arn
}

output "admin_api_alb_dns_name" {
  value = aws_lb.admin_api.dns_name
}

output "admin_api_target_group_arn" {
  value = aws_lb_target_group.admin_api.arn
}

output "admin_api_health_check_command" {
  value = "curl -v http://${aws_lb.admin_api.dns_name}/health"
}

output "admin_api_login_check_command" {
  value = "curl -v http://${aws_lb.admin_api.dns_name}/api/v1/admin/auth/login"
}

# --- AIOps / catalog ALBs (referenced as data sources) ---------------------

output "aiops_api_alb_dns_name" {
  value = data.aws_lb.aiops_api.dns_name
}

output "aiops_api_alb_security_group_id" {
  value = aws_security_group.aiops_api_alb.id
}

output "aiops_api_alb_security_group_name" {
  value = aws_security_group.aiops_api_alb.name
}

output "catalog_api_alb_dns_name" {
  value = data.aws_lb.catalog_api.dns_name
}

output "catalog_api_alb_security_group_id" {
  value = aws_security_group.catalog_api_alb.id
}

output "catalog_api_alb_security_group_name" {
  value = aws_security_group.catalog_api_alb.name
}

# --- CloudFront ------------------------------------------------------------

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.web_edge.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.web_edge.domain_name
}

output "cloudfront_admin_url" {
  value = "https://${aws_cloudfront_distribution.web_edge.domain_name}/admin/"
}

output "cloudfront_admin_api_login_check_command" {
  value = "curl -v https://${aws_cloudfront_distribution.web_edge.domain_name}/api/v1/admin/auth/login"
}

output "cloudfront_catalog_products_check_command" {
  value = "curl -v https://${aws_cloudfront_distribution.web_edge.domain_name}/api/v1/products"
}

# --- Extra outputs for downstream ACM / WAF / Route 53 wiring ---------------

output "distribution_arn" {
  description = "CloudFront distribution ARN (used to associate a WAFv2 Web ACL)."
  value       = aws_cloudfront_distribution.web_edge.arn
}

output "distribution_hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route 53 alias records."
  value       = aws_cloudfront_distribution.web_edge.hosted_zone_id
}
