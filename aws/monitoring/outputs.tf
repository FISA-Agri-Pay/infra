output "loki_release_name" {
  description = "Loki Helm release name."
  value       = helm_release.loki.name
}

output "loki_namespace" {
  description = "Kubernetes namespace where Loki is installed."
  value       = helm_release.loki.namespace
}

output "loki_chart_version" {
  description = "Loki Helm chart version."
  value       = helm_release.loki.version
}

output "loki_gateway_check_command" {
  description = "Command to check Loki gateway service."
  value       = "kubectl get svc -n ${var.namespace} | findstr /i loki"
}