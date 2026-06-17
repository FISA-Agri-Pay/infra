variable "region" {
  description = "AWS region for the recorded data resources."
  type        = string
  default     = "ap-northeast-2"
}

variable "db_engine" {
  description = "Placeholder DB engine. Replace with the console value before trusting Infracost estimates."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Placeholder DB engine version. Replace with the console value."
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "Cost-sensitive placeholder for the primary RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage_gb" {
  description = "Cost-sensitive placeholder for allocated RDS storage in GiB."
  type        = number
  default     = 100
}

variable "db_storage_type" {
  description = "Cost-sensitive placeholder for RDS storage type."
  type        = string
  default     = "gp3"
}

variable "db_multi_az" {
  description = "Cost-sensitive placeholder for primary RDS Multi-AZ setting."
  type        = bool
  default     = false
}

variable "db_enabled_cloudwatch_logs_exports" {
  description = "Placeholder RDS log exports for monitoring/auditing. Confirm engine-specific log types in the console."
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "primary_db_identifier" {
  description = "Recorded primary DB identifier."
  type        = string
  default     = "kkpp-primary-db"
}

variable "dr_db_identifier" {
  description = "Recorded DR/read-replica DB identifier placeholder."
  type        = string
  default     = "kkpp-dr-db"
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group name placeholder from the console."
  type        = string
  default     = "kkpp-db-subnet-group"
}

variable "db_security_group_ids" {
  description = "Existing DB security group IDs placeholder from the console."
  type        = list(string)
  default     = ["sg-00000000000000000"]
}

variable "dms_replication_instance_class" {
  description = "Cost-sensitive placeholder for the DMS replication instance class."
  type        = string
  default     = "dms.t3.medium"
}

variable "dms_allocated_storage_gb" {
  description = "Cost-sensitive placeholder for DMS allocated storage in GiB."
  type        = number
  default     = 50
}

variable "dms_source_endpoint_arn" {
  description = "Existing DMS source endpoint ARN placeholder. Replace with console value."
  type        = string
  default     = "arn:aws:dms:ap-northeast-2:153585581837:endpoint:AAAAAAAAAAAAAAAAAAAAAA"
}

variable "dms_target_endpoint_arn" {
  description = "Existing DMS target endpoint ARN placeholder. Replace with console value."
  type        = string
  default     = "arn:aws:dms:ap-northeast-2:153585581837:endpoint:BBBBBBBBBBBBBBBBBBBBBB"
}
