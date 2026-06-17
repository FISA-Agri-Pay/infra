variable "region" {
  description = "AWS region for the recorded networking resources."
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "Recorded VPC CIDR from the console."
  type        = string
  default     = "10.0.0.0/20"
}

variable "availability_zones" {
  description = "Two AZs used by the recorded public/private subnet layout. Confirm against the console before using this as an estimate source."
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "Placeholder public subnet CIDRs. Replace with console values before trusting subnet documentation."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Placeholder private subnet CIDRs. Replace with console values before trusting subnet documentation."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "nat_eip_allocation_ids" {
  description = "Existing NAT EIP allocation IDs from the console. Placeholder IDs keep this record useful for Infracost and must not be applied."
  type        = list(string)
  default     = ["eipalloc-00000000000000000", "eipalloc-11111111111111111"]
}

variable "include_vpn_placeholder" {
  description = "Set true only when documenting a known VPN gateway in this record-only layer."
  type        = bool
  default     = false
}
