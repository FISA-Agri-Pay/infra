locals {
  common_tags = {
    Project   = "kkpp"
    ManagedBy = "terraform"
    Service   = "web-edge"
  }
}

# ---------------------------------------------------------------------------
# ACM certificate (DNS-validated). Validation records + the
# aws_acm_certificate_validation waiter live in the aws/dns module, which owns
# the Route 53 hosted zone.
# ---------------------------------------------------------------------------
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, { Name = "${var.domain_name}-cert" })
}

# ---------------------------------------------------------------------------
# WAFv2 Web ACL for the CloudFront distribution.
# ---------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "kkpp-web-edge-cloudfront"
  description = "WAF for the kkpp web-edge CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitPerIP"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "kkpp-web-edge-cloudfront"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-cloudfront-waf" })
}
