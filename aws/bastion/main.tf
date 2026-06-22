# Record-only Terraform for the console-created RDS bastion host.
# This is an IaC documentation and Infracost input layer. Do not apply it.
#
# A small jump host used to reach the private RDS instances. It is normally
# kept stopped and started on demand.

locals {
  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "bastion"
    Component   = "jump-host"
  }
}

resource "aws_instance" "rds_bastion" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  tags = merge(local.common_tags, { Name = "kkpp-rds-bastion-host" })
}
