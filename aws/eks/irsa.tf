# Record-only IAM for service-account access (IRSA + EKS Pod Identity).
# Do not apply. Documents console-created roles attached to the EKS cluster.
#
# Customer-managed policy documents (payment producer/consumer, AIOps S3/VPN
# read-only) are NOT reproduced here; roles reference them by ARN only.

locals {
  oidc_issuer = aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_host   = replace(local.oidc_issuer, "https://", "")
}

# OIDC identity provider that backs IRSA trust on this cluster.
resource "aws_iam_openid_connect_provider" "eks" {
  url             = local.oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]
}

# --- EBS CSI driver (IRSA) ---
resource "aws_iam_role" "ebs_csi_driver" {
  name = "AmazonEKS_EBS_CSI_DriverRole_${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Name = "AmazonEKS_EBS_CSI_DriverRole_${var.cluster_name}" })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# --- CloudWatch agent (EKS Pod Identity) ---
resource "aws_iam_role" "cloudwatch_agent" {
  name = "${var.cluster_name}-cloudwatch-agent-pod-identity-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-cloudwatch-agent-pod-identity-role" })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# --- service-catalog app (IRSA) ---
resource "aws_iam_role" "service_catalog" {
  name = "kkpp-dev-service-catalog-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_host}:sub" = "system:serviceaccount:service-catalog:service-catalog-sa"
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Name = "kkpp-dev-service-catalog-irsa" })
}

# Customer-managed SQS access policies (documents managed in console).
resource "aws_iam_role_policy_attachment" "service_catalog" {
  for_each = toset([
    "kkpp-dev-payment-request-producer",
    "kkpp-dev-payment-pin-verified-consumer",
  ])

  role       = aws_iam_role.service_catalog.name
  policy_arn = "arn:aws:iam::${var.account_id}:policy/${each.value}"
}

# --- AIOps topology knowledge (IRSA, read-only) ---
resource "aws_iam_role" "aiops_topology_knowledge" {
  name = "kkpp-aiops-topology-knowledge-readonly"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "${local.oidc_host}:sub" = [
            "system:serviceaccount:aiops:mcp-aiops-backend",
            "system:serviceaccount:default:mcp-aiops-backend",
          ]
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Name = "kkpp-aiops-topology-knowledge-readonly" })
}

resource "aws_iam_role_policy_attachment" "aiops_topology_knowledge" {
  role       = aws_iam_role.aiops_topology_knowledge.name
  policy_arn = "arn:aws:iam::${var.account_id}:policy/KkppAiopsTopologyKnowledgeS3ReadOnly"
}

# The role also carries an inline policy `KkppAiopsAwsVpnCloudWatchReadOnly`
# (CloudWatch read access for the on-prem VPN). Its document is managed in the
# console and intentionally not reproduced in this record-only layer.
