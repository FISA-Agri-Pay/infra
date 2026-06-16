data "aws_caller_identity" "current" {}

locals {
  cur_bucket_name = coalesce(var.cur_bucket_name, "kkpp-cur-reports-${data.aws_caller_identity.current.account_id}")

  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "finops"
    Component   = "finops"
  }

  cost_allocation_tags = toset([
    "Project",
    "Service",
    "Environment",
    "Component",
  ])
}

resource "aws_ce_cost_allocation_tag" "this" {
  provider = aws.billing
  for_each = local.cost_allocation_tags

  tag_key = each.value
  status  = "Active"
}

resource "aws_s3_bucket" "cur" {
  bucket = local.cur_bucket_name

  tags = merge(local.common_tags, {
    Name = local.cur_bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket = aws_s3_bucket.cur.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cur" {
  bucket = aws_s3_bucket.cur.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "cur" {
  statement {
    sid = "AllowBillingReportsBucketRead"

    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
    ]

    resources = [aws_s3_bucket.cur.arn]
  }

  statement {
    sid = "AllowBillingReportsObjectWrite"

    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cur.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cur" {
  bucket = aws_s3_bucket.cur.id
  policy = data.aws_iam_policy_document.cur.json
}

resource "aws_cur_report_definition" "kkpp" {
  provider = aws.billing

  report_name                = var.cur_report_name
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  additional_artifacts       = ["ATHENA"]
  s3_bucket                  = aws_s3_bucket.cur.bucket
  s3_prefix                  = var.cur_s3_prefix
  s3_region                  = var.region
  report_versioning          = "OVERWRITE_REPORT"
  refresh_closed_reports     = true

  depends_on = [aws_s3_bucket_policy.cur]
}
