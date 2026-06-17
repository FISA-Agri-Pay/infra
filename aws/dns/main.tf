locals {
  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "web-edge"
    Component   = "edge"
  }
}

# Pull the ACM cert (validation options + arn) from the edge module and the
# CloudFront distribution details from the web-edge module.
data "terraform_remote_state" "edge" {
  backend = "s3"
  config = {
    bucket = "kkpp-aws-terraform-state"
    key    = "edge-security/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "web_edge" {
  backend = "s3"
  config = {
    bucket = "kkpp-aws-terraform-state"
    key    = "web-edge/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

locals {
  cf_domain_name = data.terraform_remote_state.web_edge.outputs.cloudfront_domain_name
  # CloudFront's alias target hosted zone ID is a global constant.
  cf_zone_id = "Z2FDTNDATAQYW2"
}

# ---------------------------------------------------------------------------
# Hosted zone record. Registrar name-server changes are performed manually in
# the console; do not apply this repo against production.
# ---------------------------------------------------------------------------
resource "aws_route53_zone" "this" {
  name = var.domain_name
  tags = merge(local.common_tags, { Name = var.domain_name })
}

# ---------------------------------------------------------------------------
# ACM DNS validation records (one per domain/SAN).
# ---------------------------------------------------------------------------
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in data.terraform_remote_state.edge.outputs.acm_domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id         = aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 300
  records         = [each.value.value]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  provider                = aws.us_east_1
  certificate_arn         = data.terraform_remote_state.edge.outputs.acm_certificate_arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

# ---------------------------------------------------------------------------
# Alias records → CloudFront (apex + optional www).
# ---------------------------------------------------------------------------
resource "aws_route53_record" "apex_a" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = local.cf_domain_name
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = local.cf_domain_name
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  count   = var.create_www_record ? 1 : 0
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = local.cf_domain_name
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  count   = var.create_www_record ? 1 : 0
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = local.cf_domain_name
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}
