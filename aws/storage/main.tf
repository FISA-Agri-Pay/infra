# Record-only Terraform for live console-created S3 buckets.
# This is an IaC documentation and Infracost input layer. Do not apply it.
#
# Buckets are recorded with their bucket-level configuration only. No object
# contents, bucket policies with principals, or credentials are stored here.

locals {
  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "storage"
    Component   = "object-storage"
  }
}

# --- Admin SPA static website bucket (CloudFront origin) ---
resource "aws_s3_bucket" "admin_spa" {
  bucket = "kkpp-admin-s3-bucket"

  tags = merge(local.common_tags, { Name = "kkpp-admin-s3-bucket", Role = "admin-spa" })
}

resource "aws_s3_bucket_website_configuration" "admin_spa" {
  bucket = aws_s3_bucket.admin_spa.id

  index_document {
    suffix = "index.html"
  }

  # SPA fallback: serve index.html for client-side routes.
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "admin_spa" {
  bucket = aws_s3_bucket.admin_spa.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- User SPA static website bucket (CloudFront origin) ---
resource "aws_s3_bucket" "user_spa" {
  bucket = "kkpp-s3-bucket"

  tags = merge(local.common_tags, { Name = "kkpp-s3-bucket", Role = "user-spa" })
}

resource "aws_s3_bucket_website_configuration" "user_spa" {
  bucket = aws_s3_bucket.user_spa.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "user_spa" {
  bucket = aws_s3_bucket.user_spa.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Product image assets ---
resource "aws_s3_bucket" "product_images" {
  bucket = "kkpp-product-images"

  tags = merge(local.common_tags, { Name = "kkpp-product-images", Role = "product-images" })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Secure credit document storage (KMS-encrypted) ---
resource "aws_s3_bucket" "secure_credit_docs" {
  bucket = "kkpp-secure-credit-docs-bucket"

  tags = merge(local.common_tags, { Name = "kkpp-secure-credit-docs-bucket", Role = "secure-documents" })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_credit_docs" {
  bucket = aws_s3_bucket.secure_credit_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.secure_docs_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secure_credit_docs" {
  bucket = aws_s3_bucket.secure_credit_docs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- AIOps topology knowledge store (versioned) ---
resource "aws_s3_bucket" "aiops_topology_knowledge" {
  bucket = "kkpp-aiops-topology-knowledge-${var.account_id}-${var.region}"

  tags = merge(local.common_tags, { Name = "kkpp-aiops-topology-knowledge", Role = "aiops-knowledge" })
}

resource "aws_s3_bucket_versioning" "aiops_topology_knowledge" {
  bucket = aws_s3_bucket.aiops_topology_knowledge.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aiops_topology_knowledge" {
  bucket = aws_s3_bucket.aiops_topology_knowledge.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
