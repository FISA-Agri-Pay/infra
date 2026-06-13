# ---------------------------------------------------------------------------
# Security groups for the internal ALBs fronted by CloudFront VPC origins.
# Ingress from the CloudFront origin-facing prefix list + VPC/on-prem ranges.
# ---------------------------------------------------------------------------

resource "aws_security_group" "admin_api_alb" {
  name        = "kkpp-web-edge-admin-api-alb-sg"
  description = "Security group for the admin API internal ALB"
  vpc_id      = var.vpc_id

  ingress = [
    {
      cidr_blocks      = ["172.20.0.0/16"]
      description      = "HTTP access to the internal ALB"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = []
      description      = "HTTP access from CloudFront origin-facing servers"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id]
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
  ]

  egress = [
    {
      cidr_blocks      = ["10.30.2.100/32"]
      description      = "HTTP to on-premises admin ingress"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
  ]

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-admin-api-alb-sg" })
}

resource "aws_security_group" "aiops_api_alb" {
  name        = "kkpp-web-edge-aiops-api-alb-sg"
  description = "Security group for the MCP AIOps internal ALB managed by EKS"
  vpc_id      = var.vpc_id

  ingress = [
    {
      cidr_blocks      = ["10.30.0.0/16"]
      description      = "HTTP from on-prem routed network to AIOps internal ALB"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = ["172.20.0.0/16"]
      description      = "HTTP access from VPC for validation"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = ["192.168.100.0/24"]
      description      = "HTTP from on-prem Kubernetes nodes to AIOps internal ALB"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = []
      description      = "HTTP access from CloudFront origin-facing servers"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id]
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
  ]

  egress = [
    {
      cidr_blocks      = ["172.20.0.0/16"]
      description      = "Outbound traffic to EKS pod and node targets"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-aiops-api-alb-sg" })
}

resource "aws_security_group" "catalog_api_alb" {
  name        = "kkpp-web-edge-catalog-api-alb-sg"
  description = "Security group for the service-catalog internal ALB managed by EKS"
  vpc_id      = var.vpc_id

  ingress = [
    {
      cidr_blocks      = ["172.20.0.0/16"]
      description      = "HTTP access from VPC for validation"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = []
      description      = "HTTP access from CloudFront origin-facing servers"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id]
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
  ]

  egress = [
    {
      cidr_blocks      = ["172.20.0.0/16"]
      description      = "Outbound traffic to EKS pod and node targets"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-catalog-api-alb-sg" })
}

# ---------------------------------------------------------------------------
# Admin API internal ALB (the only ALB created by this module; the aiops and
# catalog ALBs are owned by the app stack and only referenced as data sources).
# ---------------------------------------------------------------------------

resource "aws_lb" "admin_api" {
  name                       = "kkpp-web-edge-admin-api"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.admin_api_alb.id]
  subnets                    = var.alb_subnet_ids
  drop_invalid_header_fields = true
  idle_timeout               = 60
  client_keep_alive          = 3600

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-admin-api" })
}

resource "aws_lb_target_group" "admin_api" {
  name        = "kkpp-web-edge-admin-api"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-admin-api" })
}

resource "aws_lb_target_group_attachment" "admin_api_onprem_ingress" {
  target_group_arn  = aws_lb_target_group.admin_api.arn
  target_id         = "10.30.2.100"
  port              = 80
  availability_zone = "all"
}

resource "aws_lb_listener" "admin_api_http" {
  load_balancer_arn = aws_lb.admin_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin_api.arn
  }

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-admin-api-http" })
}

resource "aws_lb_listener_rule" "admin_api_host_rewrite" {
  listener_arn = aws_lb_listener.admin_api_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin_api.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/admin/*"]
    }
  }

  tags = merge(local.common_tags, { Name = "kkpp-web-edge-admin-api-host-rewrite" })
}
