# KKPP EKS Terraform Record

This layer records the existing `kkpp-eks` cluster shape for infrastructure
documentation and Infracost input.

Do not run `terraform apply` for this layer. Do not use this repository to
create, import, or take over management of the live EKS cluster, node group, or
subnet tags.

Recorded defaults used by Infracost:

- Cluster name: `kkpp-eks`
- Region: `ap-northeast-2`
- Environment tag: `dev`
- Component tag: `compute`
- Node instance type: `t3.medium`
- Desired/min/max size: `2/1/3`

Live subnet, node group, add-on, and IAM details should be confirmed in the AWS
console before relying on this record for anything beyond estimation.
