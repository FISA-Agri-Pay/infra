output "sns_topic_name" {
  description = "Recorded SNS topic name for CloudWatch alerts."
  value       = aws_sns_topic.cloudwatch_alerts.name
}

output "lambda_function_name" {
  description = "Recorded Slack alert Lambda function name."
  value       = aws_lambda_function.slack_alerts.function_name
}

output "slack_webhook_secret_name" {
  description = "Recorded Slack webhook secret name (value not stored)."
  value       = aws_secretsmanager_secret.slack_webhook.name
}
