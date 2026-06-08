locals {
  lb_additional_resource_tags = join(",", [
    for key, value in var.common_tags : "${key}=${value}"
  ])
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

resource "helm_release" "loki" {
  name             = "loki"
  namespace        = var.namespace
  create_namespace = false

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.loki_chart_version

  wait    = true
  timeout = 600

  values = [
    templatefile("${path.module}/values/loki-values.yaml.tftpl", {
      lb_additional_resource_tags = local.lb_additional_resource_tags
    })
  ]
}