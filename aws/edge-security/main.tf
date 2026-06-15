locals {
  common_tags = {
    Project   = "kkpp"
    ManagedBy = "terraform"
    Service   = "web-edge"
  }

  # CommonRuleSet sub-rules that false-positive on binary multipart uploads
  # (image bytes trip the body inspectors; uploads always exceed the 8 KB body
  # limit). Each is overridden to Count below so it only labels the request, and
  # the BlockManagedBodyRulesExceptUploads rule re-blocks the label on every path
  # EXCEPT the admin image-upload endpoint — keeping full protection elsewhere.
  crs_body_overrides = {
    "SizeRestrictions_BODY"   = "awswaf:managed:aws:core-rule-set:SizeRestrictions_Body"
    "CrossSiteScripting_BODY" = "awswaf:managed:aws:core-rule-set:CrossSiteScripting_Body"
    "GenericRFI_BODY"         = "awswaf:managed:aws:core-rule-set:GenericRFI_Body"
  }

  upload_path_prefix = "/api/v1/admin/products/images"
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

        # Body inspectors that false-positive on binary image uploads — flipped
        # to Count here, then re-blocked off the upload path (see locals).
        dynamic "rule_action_override" {
          for_each = local.crs_body_overrides
          content {
            name = rule_action_override.key
            action_to_use {
              count {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # ---------------------------------------------------------------------------
  # Re-block the body-inspection labels set by CommonRuleSet above on every path
  # EXCEPT the admin image-upload endpoint. Runs after CommonRuleSet (priority
  # 10) so the labels are present.
  # ---------------------------------------------------------------------------
  rule {
    name     = "BlockManagedBodyRulesExceptUploads"
    priority = 11

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          or_statement {
            dynamic "statement" {
              for_each = local.crs_body_overrides
              content {
                label_match_statement {
                  scope = "LABEL"
                  key   = statement.value
                }
              }
            }
          }
        }

        statement {
          not_statement {
            statement {
              byte_match_statement {
                search_string         = local.upload_path_prefix
                positional_constraint = "STARTS_WITH"

                field_to_match {
                  uri_path {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockManagedBodyRulesExceptUploads"
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
