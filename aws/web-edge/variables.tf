variable "region" {
  description = "AWS region for the web-edge resources (ALBs, security groups). CloudFront itself is global."
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_id" {
  description = "VPC that hosts the internal ALBs and their security groups."
  type        = string
  default     = "vpc-000657d90c7a6085c"
}

variable "alb_subnet_ids" {
  description = "Private (internal-elb) subnets for the admin-api internal ALB."
  type        = list(string)
  default     = ["subnet-0dc55bbd450ac9f03", "subnet-0fa7830f7ccadd210"]
}
