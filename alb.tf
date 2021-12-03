#TODO: Double check Security Group if they are correct

# ---------------------------------------------------------------------------------------------------------------------
# S3 Bucket for ALB Access Logs
# ---------------------------------------------------------------------------------------------------------------------
module "s3_bucket_for_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "2.11.1"


  bucket = lower("${var.prefix}-${var.user_defined}-alb-logs")
  acl    = "log-delivery-write"

  # Allow deletion of non-empty bucket
  force_destroy = true

  attach_elb_log_delivery_policy = true  # Required for ALB logs
  attach_lb_log_delivery_policy  = true  # Required for ALB/NLB logs
}

# ---------------------------------------------------------------------------------------------------------------------
# Application Load Balancer (ALB) with Target Groups
# ---------------------------------------------------------------------------------------------------------------------
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "${var.prefix}-${var.user_defined}-public-alb"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  security_groups    = [module.alb_https_security_group.security_group_id, module.alb_http_security_group.security_group_id]

  access_logs = {
    bucket = lower("${var.prefix}-${var.user_defined}-alb-logs")
  }

  #TODO: create a SSL cert
  #extra_ssl_certs = []

  target_groups = [
    {
      name                 = "${var.prefix}-${var.user_defined}-blue-tg"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "ip"
      deregistration_delay = 300
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-299"
      }
      protocol_version = "HTTP1"
      tags = {
        Env = var.env
        CostCenter = var.costcenter
        SSN = var.ssn
        SubOwner = var.subowner
      }
    },
    {
      name                 = "${var.prefix}-${var.user_defined}-green-tg"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "ip"
      deregistration_delay = 300
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-299"
      }
      protocol_version = "HTTP1"
      tags = {
        Env = var.env
        CostCenter = var.costcenter
        SSN = var.ssn
        SubOwner = var.subowner
      }
    },
  ]

  # https_listeners = [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
  #     target_group_index = 0
  #   }
  # ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }

  depends_on = [
    module.s3_bucket_for_logs
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Application Load Balancer (ALB) with Target Groups
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener_rule" "this" {
  listener_arn = module.alb.http_tcp_listener_arns[0]
  priority     = 1

  action {
    type = "forward"
    forward {
      target_group {
        arn    = module.alb.target_group_arns[0]
        weight = 100
      }

      target_group {
        arn    = module.alb.target_group_arns[1]
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}