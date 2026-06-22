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

## Add-ons (`main.tf`)

`vpc-cni`, `coredns`, `kube-proxy`, `eks-pod-identity-agent`, `aws-ebs-csi-driver`,
`amazon-cloudwatch-observability`.

## Service-account IAM (`irsa.tf`)

Roles attached to the cluster via IRSA (OIDC) or EKS Pod Identity:

| Role | Mechanism | Service account | Policies |
|---|---|---|---|
| `AmazonEKS_EBS_CSI_DriverRole_kkpp-eks` | IRSA | `kube-system:ebs-csi-controller-sa` | `AmazonEBSCSIDriverPolicy` (AWS) |
| `kkpp-eks-cloudwatch-agent-pod-identity-role` | Pod Identity | (cloudwatch agent) | `CloudWatchAgentServerPolicy` (AWS) |
| `kkpp-dev-service-catalog-irsa` | IRSA | `service-catalog:service-catalog-sa` | payment producer/consumer (customer) |
| `kkpp-aiops-topology-knowledge-readonly` | IRSA | `aiops`/`default:mcp-aiops-backend` | AIOps S3 RO + VPN/CloudWatch RO inline (customer) |

Customer-managed policy **documents** are not reproduced here; roles reference
them by ARN only (`account_id` is a templated placeholder).

Live subnet, node group, add-on, and IAM details should be confirmed in the AWS
console before relying on this record for anything beyond estimation.
