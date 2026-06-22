output "repository_names" {
  description = "Recorded ECR repository names."
  value = [
    aws_ecr_repository.service_catalog.name,
    aws_ecr_repository.mcp_aiops_backend.name,
  ]
}
