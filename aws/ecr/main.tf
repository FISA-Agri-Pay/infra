# Record-only Terraform for live console-created ECR repositories.
# This is an IaC documentation and Infracost input layer. Do not apply it.

locals {
  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "ecr"
    Component   = "container-registry"
  }
}

# Container image registry for the service-catalog application.
resource "aws_ecr_repository" "service_catalog" {
  name                 = "service-catalog"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, { Name = "service-catalog" })
}

# Container image registry for the AIOps MCP backend.
resource "aws_ecr_repository" "mcp_aiops_backend" {
  name                 = "kkpp/mcp-aiops-backend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, { Name = "kkpp-mcp-aiops-backend" })
}
