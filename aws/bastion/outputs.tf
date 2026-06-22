output "bastion_name" {
  description = "Recorded RDS bastion host name."
  value       = aws_instance.rds_bastion.tags["Name"]
}
