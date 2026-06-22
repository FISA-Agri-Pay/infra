# Record-only CloudWatch alarms that feed the alerting stack in main.tf.
# Do not apply. These document the console/addon-created alarms.
#
# Alarm coverage:
#   - EKS ContainerInsights cluster/node alarms -> SNS topic
#   - SQS queue depth/age alarms (currently no notification action wired)
#
# The cluster/pod-level "recommended alarms" (PVC problem, pod not healthy,
# pod restart high, pod waiting) are metric-math expression alarms auto-created
# and managed by the amazon-cloudwatch-observability addon; they are documented
# in README.md rather than reproduced here.

locals {
  alarm_prefix = "EKS-${var.cluster_name}"
}

# --- EKS cluster-level ---
resource "aws_cloudwatch_metric_alarm" "deployment_replicas_unavailable" {
  alarm_name          = "${local.alarm_prefix}-KubernetesDeploymentReplicasUnavailable"
  namespace           = "ContainerInsights"
  metric_name         = "status_replicas_unavailable"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 10
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(local.common_tags, { Name = "${local.alarm_prefix}-deployment-replicas-unavailable" })
}

# --- EKS node-level (one pair per worker node, addon-managed) ---
resource "aws_cloudwatch_metric_alarm" "node_not_ready" {
  for_each = { for n in var.eks_nodes : n.node_name => n }

  alarm_name          = "${local.alarm_prefix}-KubernetesNodeNotReady-${each.value.node_name}-"
  namespace           = "ContainerInsights"
  metric_name         = "node_status_condition_ready"
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 3
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    NodeName    = each.value.node_name
    InstanceId  = each.value.instance_id
  }

  tags = merge(local.common_tags, { Name = "${local.alarm_prefix}-node-not-ready" })
}

resource "aws_cloudwatch_metric_alarm" "node_root_fs_almost_full" {
  for_each = { for n in var.eks_nodes : n.node_name => n }

  alarm_name          = "${local.alarm_prefix}-KubernetesNodeRootFilesystemAlmostFull-${each.value.node_name}-"
  namespace           = "ContainerInsights"
  metric_name         = "node_filesystem_utilization"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 85
  period              = 60
  evaluation_periods  = 10
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    NodeName    = each.value.node_name
    InstanceId  = each.value.instance_id
  }

  tags = merge(local.common_tags, { Name = "${local.alarm_prefix}-node-root-fs-almost-full" })
}

# --- SQS queue alarms ---
# Recorded as-is: these alarms currently have no notification action wired
# (alarm_actions empty). Queue names match the aws/messaging layer.
locals {
  sqs_visible_alarms = {
    "kkpp-dev-payment-request-visible-messages"      = "credit-payment-requested.fifo"
    "kkpp-dev-payment-pin-verified-visible-messages" = "payment-pin-verified.fifo"
  }

  sqs_oldest_age_alarms = {
    "kkpp-dev-payment-request-oldest-message-age"      = "credit-payment-requested.fifo"
    "kkpp-dev-payment-pin-verified-oldest-message-age" = "payment-pin-verified.fifo"
  }

  sqs_dlq_alarms = {
    "kkpp-dev-payment-request-dlq-visible-messages"      = "credit-payment-requested-dlq.fifo"
    "kkpp-dev-payment-pin-verified-dlq-visible-messages" = "payment-pin-verified-dlq.fifo"
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_visible_messages" {
  for_each = local.sqs_visible_alarms

  alarm_name          = each.key
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 100
  period              = 60
  evaluation_periods  = 5

  dimensions = {
    QueueName = each.value
  }

  tags = merge(local.common_tags, { Name = each.key })
}

resource "aws_cloudwatch_metric_alarm" "sqs_oldest_message_age" {
  for_each = local.sqs_oldest_age_alarms

  alarm_name          = each.key
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 300
  period              = 60
  evaluation_periods  = 5

  dimensions = {
    QueueName = each.value
  }

  tags = merge(local.common_tags, { Name = each.key })
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_visible_messages" {
  for_each = local.sqs_dlq_alarms

  alarm_name          = each.key
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 1

  dimensions = {
    QueueName = each.value
  }

  tags = merge(local.common_tags, { Name = each.key })
}
