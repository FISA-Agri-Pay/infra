# Record-only Terraform for the live console-created CloudWatch -> Slack
# alerting stack for the EKS cluster.
# This is an IaC documentation and Infracost input layer. Do not apply it.
#
# Flow: CloudWatch alarms -> SNS topic -> Lambda -> Slack incoming webhook.
# The Slack webhook URL and Lambda function code are NOT stored in this repo.

locals {
  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "alerting"
    Component   = "cloudwatch-slack"
  }

  name_prefix = "eks-${var.cluster_name}"
}

# SNS topic that CloudWatch alarms publish to.
resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "${local.name_prefix}-k8s-cloudwatch-alerts"

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-k8s-cloudwatch-alerts" })
}

# Secret holding the Slack incoming webhook URL. The value is managed outside
# this repo (console / pipeline); only the secret container is recorded here.
resource "aws_secretsmanager_secret" "slack_webhook" {
  name        = "eks/${var.cluster_name}/cloudwatch/slack-webhook"
  description = "Record of the Slack webhook secret; no secret value is stored in this repo."

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-slack-webhook" })
}

# Execution role for the alert-forwarding Lambda. Inline/attached policies
# (logs + secretsmanager:GetSecretValue) are managed in the console.
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-cloudwatch-slack-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cloudwatch-slack-lambda-role" })
}

# Lambda that formats SNS alarm payloads and posts to Slack.
resource "aws_lambda_function" "slack_alerts" {
  function_name = "${local.name_prefix}-cloudwatch-slack-alerts"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  architectures = ["x86_64"]
  timeout       = 15
  memory_size   = 128

  # Function code is not committed; this points at a placeholder package.
  filename = var.lambda_package_path

  environment {
    variables = {
      CLUSTER_NAME            = var.cluster_name
      SLACK_WEBHOOK_SECRET_ID = aws_secretsmanager_secret.slack_webhook.arn
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cloudwatch-slack-alerts" })
}

# Wire the SNS topic to the Lambda.
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alerts.arn
}

resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alerts.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_alerts.arn
}
