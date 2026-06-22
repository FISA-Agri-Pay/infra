variable "region" {
  description = "AWS region for the recorded SQS queues."
  type        = string
  default     = "ap-northeast-2"
}

variable "message_retention_seconds" {
  description = "Message retention period for all queues. Recorded value: 14 days."
  type        = number
  default     = 1209600
}

variable "max_receive_count" {
  description = "Redrive policy maxReceiveCount before a message moves to its DLQ."
  type        = number
  default     = 5
}
