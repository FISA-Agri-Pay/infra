output "primary_db_identifier" {
  description = "Recorded primary DB identifier."
  value       = aws_db_instance.primary.identifier
}

output "dr_db_identifier" {
  description = "Recorded DR/read-replica DB identifier."
  value       = aws_db_instance.dr_standby.identifier
}

output "dms_replication_instance_id" {
  description = "Recorded DMS replication instance ID."
  value       = aws_dms_replication_instance.this.replication_instance_id
}
