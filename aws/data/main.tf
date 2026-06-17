# Record-only Terraform for live console-created data resources.
# This is an IaC documentation and Infracost input layer. Do not apply it.

locals {
  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "data"
    Component   = "data"
  }
}

resource "aws_kms_key" "data" {
  description             = "Record of the data-layer KMS key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, { Name = "kkpp-data-kms" })
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "kkpp/data/db-credentials"
  description = "Record of the DB credentials secret; no secret value is stored in this repo."
  kms_key_id  = aws_kms_key.data.arn

  tags = merge(local.common_tags, { Name = "kkpp-data-db-credentials" })
}

resource "aws_db_instance" "primary" {
  identifier                  = var.primary_db_identifier
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage_gb
  storage_type                = var.db_storage_type
  multi_az                    = var.db_multi_az
  db_subnet_group_name        = var.db_subnet_group_name
  vpc_security_group_ids      = var.db_security_group_ids
  username                    = "placeholder_admin"
  manage_master_user_password = true
  storage_encrypted           = true
  kms_key_id                  = aws_kms_key.data.arn
  skip_final_snapshot         = false

  tags = merge(local.common_tags, { Name = var.primary_db_identifier, Role = "primary" })
}

resource "aws_db_instance" "dr_standby" {
  identifier          = var.dr_db_identifier
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.db_instance_class
  storage_type        = var.db_storage_type
  multi_az            = false
  skip_final_snapshot = false

  tags = merge(local.common_tags, { Name = var.dr_db_identifier, Role = "dr-standby" })
}

resource "aws_dms_replication_instance" "this" {
  replication_instance_id    = "kkpp-data-dms"
  replication_instance_class = var.dms_replication_instance_class
  allocated_storage          = var.dms_allocated_storage_gb
  publicly_accessible        = false
  multi_az                   = false

  tags = merge(local.common_tags, { Name = "kkpp-data-dms" })
}

resource "aws_dms_replication_task" "placeholder" {
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.this.replication_instance_arn
  replication_task_id      = "kkpp-data-dms-task"
  source_endpoint_arn      = var.dms_source_endpoint_arn
  target_endpoint_arn      = var.dms_target_endpoint_arn

  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection"
        "rule-id"   = "1"
        "rule-name" = "placeholder"
        "object-locator" = {
          "schema-name" = "%"
          "table-name"  = "%"
        }
        "rule-action" = "include"
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "kkpp-data-dms-task" })
}
