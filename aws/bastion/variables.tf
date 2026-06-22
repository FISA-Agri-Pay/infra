variable "region" {
  description = "AWS region for the recorded bastion host."
  type        = string
  default     = "ap-northeast-2"
}

variable "ami_id" {
  description = "AMI ID for the bastion host. Templated placeholder; the real value is in the console."
  type        = string
  default     = "ami-00000000000000000"
}

variable "subnet_id" {
  description = "Public subnet ID the bastion lives in. Templated placeholder."
  type        = string
  default     = "subnet-00000000000000000"
}

variable "security_group_ids" {
  description = "Security group IDs attached to the bastion. Templated placeholder."
  type        = list(string)
  default     = ["sg-00000000000000000"]
}

variable "key_name" {
  description = "EC2 key pair name for SSH access. Templated placeholder; the key material is never stored in this repo."
  type        = string
  default     = "kkpp-bastion-key"
}
