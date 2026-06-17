# AWS Networking

Configuration and notes for VPC, subnet, routing, security groups, and VPN
connectivity.

This layer is record-only Terraform for console-created AWS resources. It exists
to document the current VPC shape and provide Infracost input. Do not run
`terraform apply`, do not import live resources into this layer, and do not use
these placeholders as an operational rollout plan.

Known values:

- Region: `ap-northeast-2`
- VPC CIDR: `10.0.0.0/20`
- Component tag: `network`

Values that must be confirmed in the AWS console before this record is trusted:

- Public/private subnet CIDRs and AZ placement
- NAT EIP allocation IDs
- Route targets and any custom route table entries
- VPN gateway/customer gateway/site-to-site VPN details
