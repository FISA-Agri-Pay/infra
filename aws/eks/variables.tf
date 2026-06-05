variable "region" {
  description = "AWS region where the EKS cluster will be created."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID connected to the internal network VPN."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS worker nodes."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for public LoadBalancer resources."
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS managed node group."
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
}

variable "min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
}

variable "max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
}
