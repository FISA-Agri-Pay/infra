# ---------------------------------------------------------------------------
# CloudFront functions (viewer-request SPA rewrites)
# ---------------------------------------------------------------------------

resource "aws_cloudfront_function" "admin_spa_rewrite" {
  name    = "kkpp-web-edge-admin-spa-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite admin SPA routes to /admin/index.html"
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      if (uri === "/" || uri === "/admin" || uri === "/admin/") {
        request.uri = "/admin/index.html";
        return request;
      }

      if (uri.indexOf("/admin/") === 0) {
        var lastSegment = uri.substring(uri.lastIndexOf("/") + 1);
        if (lastSegment.indexOf(".") === -1) {
          request.uri = "/admin/index.html";
        }
      }

      return request;
    }
  EOT
}

resource "aws_cloudfront_function" "user_spa_rewrite" {
  name    = "kkpp-web-edge-user-spa-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite user SPA routes to /user/index.html"
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      if (uri === "/user" || uri === "/user/") {
        request.uri = "/user/index.html";
        return request;
      }

      if (uri.indexOf("/user/") === 0) {
        var lastSegment = uri.substring(uri.lastIndexOf("/") + 1);
        if (lastSegment.indexOf(".") === -1) {
          request.uri = "/user/index.html";
        }
      }

      return request;
    }
  EOT
}

# ---------------------------------------------------------------------------
# CloudFront VPC origins (point at the internal ALBs)
# ---------------------------------------------------------------------------

resource "aws_cloudfront_vpc_origin" "admin_api_alb" {
  vpc_origin_endpoint_config {
    name                   = "kkpp-web-edge-admin-api-alb"
    arn                    = aws_lb.admin_api.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-admin-api-alb" })
}

resource "aws_cloudfront_vpc_origin" "aiops_api_alb" {
  vpc_origin_endpoint_config {
    name                   = "kkpp-web-edge-aiops-api-alb"
    arn                    = data.aws_lb.aiops_api.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-aiops-api-alb" })
}

resource "aws_cloudfront_vpc_origin" "catalog_api_alb" {
  vpc_origin_endpoint_config {
    name                   = "kkpp-web-edge-service-catalog-api-alb"
    arn                    = data.aws_lb.catalog_api.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

# ---------------------------------------------------------------------------
# Cache behaviors driven by an ordered local list. ORDER IS SIGNIFICANT and
# must match the live distribution to avoid spurious diffs.
# ---------------------------------------------------------------------------

locals {
  api_allowed = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  api_cached  = ["GET", "HEAD", "OPTIONS"]
  s3_cached   = ["GET", "HEAD"]

  cache_api = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
  cache_s3  = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  orp_api   = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewer

  aiops_prefix_rewrite_arn = "arn:aws:cloudfront::153585581837:function/kkpp-web-edge-aiops-prefix-rewrite"

  ordered_behaviors = [
    { path = "/api/v1/aiops*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = local.aiops_prefix_rewrite_arn },
    { path = "/reports/ops*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/alerts*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/v1/products*", origin = "catalog-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/v1/categories*", origin = "catalog-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/v1/cart*", origin = "catalog-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/v1/checkout-requests*", origin = "catalog-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/v1/mcp*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/v1/mcp-server*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/api/v1/admin/*", origin = "admin-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/admin/static/*", origin = "admin-s3-website", allowed = ["GET", "HEAD", "OPTIONS"], cached = local.s3_cached, cache = local.cache_s3, orp = null, compress = true, func = null },
    { path = "/user/assets/*", origin = "user-s3-website", allowed = ["GET", "HEAD"], cached = local.s3_cached, cache = local.cache_s3, orp = null, compress = true, func = null },
    { path = "/user/static/*", origin = "user-s3-website", allowed = ["GET", "HEAD", "OPTIONS"], cached = local.s3_cached, cache = local.cache_s3, orp = null, compress = true, func = null },
    { path = "/user*", origin = "user-s3-website", allowed = ["GET", "HEAD", "OPTIONS"], cached = local.s3_cached, cache = local.cache_api, orp = null, compress = true, func = aws_cloudfront_function.user_spa_rewrite.arn },
    { path = "/api/v1/auth/*", origin = "admin-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = aws_cloudfront_function.admin_spa_rewrite.arn },
    { path = "/api/v1/core/*", origin = "admin-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/admin/copilot*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/admin*", origin = "admin-s3-website", allowed = ["GET", "HEAD", "OPTIONS"], cached = local.s3_cached, cache = local.cache_api, orp = null, compress = true, func = aws_cloudfront_function.admin_spa_rewrite.arn },
    { path = "/shop/*", origin = "admin-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/mcp*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/mcp-server*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/alerts/webhook*", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
    { path = "/health", origin = "aiops-api-alb", allowed = local.api_allowed, cached = local.api_cached, cache = local.cache_api, orp = local.orp_api, compress = false, func = null },
  ]
}

# ---------------------------------------------------------------------------
# The web-edge CloudFront distribution
# ---------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "web_edge" {
  comment             = "KKPP web edge distribution"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  price_class         = "PriceClass_200"
  default_root_object = "admin/index.html"
  aliases             = var.aliases
  web_acl_id          = var.web_acl_arn
  wait_for_deployment = false

  # S3 website origins
  origin {
    origin_id   = "admin-s3-website"
    domain_name = "kkpp-admin-s3-bucket.s3-website.ap-northeast-2.amazonaws.com"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  origin {
    origin_id   = "user-s3-website"
    domain_name = "kkpp-s3-bucket.s3-website.ap-northeast-2.amazonaws.com"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  # VPC (ALB) origins
  origin {
    origin_id   = "aiops-api-alb"
    domain_name = "internal-kkpp-aiops-api-2040461357.ap-northeast-2.elb.amazonaws.com"

    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.aiops_api_alb.id
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  origin {
    origin_id   = "catalog-api-alb"
    domain_name = "internal-kkpp-service-catalog-api-1951973105.ap-northeast-2.elb.amazonaws.com"

    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.catalog_api_alb.id
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  origin {
    origin_id   = "admin-api-alb"
    domain_name = "internal-kkpp-web-edge-admin-api-395646969.ap-northeast-2.elb.amazonaws.com"

    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.admin_api_alb.id
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  default_cache_behavior {
    target_origin_id       = "admin-s3-website"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = local.cache_api
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.admin_spa_rewrite.arn
    }

    grpc_config {
      enabled = false
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.ordered_behaviors
    content {
      path_pattern             = ordered_cache_behavior.value.path
      target_origin_id         = ordered_cache_behavior.value.origin
      allowed_methods          = ordered_cache_behavior.value.allowed
      cached_methods           = ordered_cache_behavior.value.cached
      cache_policy_id          = ordered_cache_behavior.value.cache
      origin_request_policy_id = ordered_cache_behavior.value.orp
      compress                 = ordered_cache_behavior.value.compress
      viewer_protocol_policy   = "redirect-to-https"

      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.func != null ? [ordered_cache_behavior.value.func] : []
        content {
          event_type   = "viewer-request"
          function_arn = function_association.value
        }
      }

      grpc_config {
        enabled = false
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn == null ? null : "sni-only"
    minimum_protocol_version       = var.acm_certificate_arn == null ? "TLSv1" : "TLSv1.2_2021"
  }

  tags = merge(local.common_tags, { Name = "kkpp-web-edge" })
}
