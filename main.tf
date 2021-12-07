# ---------------------------------------------------------------------------------------------------------------------
# Virtual Private Cloud (VPC)
# ---------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name = "${var.prefix}-${var.user_defined}"
  cidr = var.cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = var.private_subnets

	# Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  #No Internet Gateway
  create_igw = false
  
  # No database subnet
  create_database_subnet_group = false

  # Default route table
  manage_default_route_table = true

  # Naming convention overwrite
  vpc_tags = { Name = "${var.prefix}-${var.user_defined}-vpc"}

  #VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  # enable_flow_log                      = true
  # create_flow_log_cloudwatch_log_group = true
  # create_flow_log_cloudwatch_iam_role  = true
  # flow_log_max_aggregation_interval    = 60

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# Internet Gateway - Not using the IGW from the VPC module since it requires public subnets which we don't need
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.prefix}-${var.user_defined}-igw"
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
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
# Application Load Balancer (ALB) Target Groups
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
# Application Load Balancer Security Group
# ---------------------------------------------------------------------------------------------------------------------
module "alb_https_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "~> 4.0"

  name                    = "${var.prefix}-${var.user_defined}-alb-https-sg"
  description             = "Security group HTTPS ports for the application load balancer"
  vpc_id                  = module.vpc.vpc_id
  revoke_rules_on_delete  = true
  
  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

module "alb_http_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 4.0"

  name                    = "${var.prefix}-${var.user_defined}-alb-http-sg"
  description             = "Security group HTTP ports for the application load balancer"
  vpc_id                  = module.vpc.vpc_id
  revoke_rules_on_delete  = true
  
  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC DynamoDB Gateway Endpoint
# ---------------------------------------------------------------------------------------------------------------------

module "vpc_endpoint" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id

  endpoints = {
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
  }

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }

	depends_on = [module.vpc]
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC DynamoDB Gateway Endpoint Supporting Data
# ---------------------------------------------------------------------------------------------------------------------
# Data source used to avoid race condition
data "aws_vpc_endpoint_service" "dynamodb" {
  service = "dynamodb"

  filter {
    name   = "service-type"
    values = ["Gateway"]
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb.id]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Registry (ECR)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  name                 = lower("${var.prefix}-${var.user_defined}-ecr")
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Registry (ECR) Policy
# ---------------------------------------------------------------------------------------------------------------------
#TODO: Add ECR Policy
# data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
#   statement {
#     effect    = "Deny"
#     actions   = ["ecr:*"]
#     resources = ["*"]

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }

#     condition {
#       test     = "StringNotEquals"
#       variable = "aws:sourceVpce"

#       values = [data.aws_vpc_endpoint_service.dynamodb.id]
#     }
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS)
# ---------------------------------------------------------------------------------------------------------------------
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "3.4.1"

	name               = "${var.prefix}-${var.user_defined}-ecs-cluster"
  container_insights = true

  capacity_providers = ["FARGATE"]

  tags = {
		Env = var.env
		CostCenter = var.costcenter
		SSN = var.ssn
		SubOwner = var.subowner
	}

}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS) Task Definition
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family = "apis"
  requires_compatibilities = ["FARGATE"]
	network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
	
  container_definitions = jsonencode([
    {
      name      = "api-container"
      image     = "httpd"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS) Services
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "blue-service" {
  name            = "${var.prefix}-${var.user_defined}-blue-service"
  cluster         = module.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.this.arn
	launch_type 		= "FARGATE"

  desired_count = 2

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets = module.vpc.private_subnets
  }

	load_balancer {
		target_group_arn = module.alb.target_group_arns[0]
    container_name   = "api-container"
    container_port   = 80
  }

}

resource "aws_ecs_service" "green-service" {
  name            = "${var.prefix}-${var.user_defined}-green-service"
  cluster         = module.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.this.arn
	launch_type 		= "FARGATE"

  desired_count = 2

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

	network_configuration {
    subnets = module.vpc.private_subnets
  }

	load_balancer {
		target_group_arn = module.alb.target_group_arns[1]
    container_name   = "api-container"
    container_port   = 80
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# AWS WAF V2 for ALB
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "this" {
  name        = "${var.prefix}-${var.user_defined}-alb-waf"
  description = "The Application Load Balancer Firewall"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

	  rule {
    name     = "CDXP-Whitelist"
    priority = 0

    action {
      allow {}
    }

    statement {
			ip_set_reference_statement {
				arn = aws_wafv2_ip_set.this.arn
			}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "cdxp-whitelist"
      sampled_requests_enabled   = true
    }
  }

	visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.prefix}-${var.user_defined}-alb-waf"
      sampled_requests_enabled   = true
    }

}

# ---------------------------------------------------------------------------------------------------------------------
# WAF V2 CDXP IP Set
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_ip_set" "this" {
  name               = "CDXP-IP-Set"
  description        = "The CDXP IP set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.cdxp_ip_set

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# WAF V2 to ALB Association
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = "${module.alb.lb_arn}"
  web_acl_arn = "${aws_wafv2_web_acl.this.arn}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Frontend Section
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# Cloudfront Distribution
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "this" {
  enabled               = true
  is_ipv6_enabled       = true
  default_root_object   = "index.html"
  price_class           = "PriceClass_200"

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }

  origin {
    domain_name = aws_s3_bucket.bucket_blue.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.bucket_blue.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket_blue.bucket_regional_domain_name

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# Cloudfront Origin Access Identity
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.prefix}-${var.user_defined}-webapp"
}

# ---------------------------------------------------------------------------------------------------------------------
# Blue/Green S3 Buckets
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "bucket_blue" {
  bucket = lower("${var.prefix}-${var.user_defined}-webapp-blue")
  acl    = "private"

  website {
    index_document = "index.html"
  }

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

resource "aws_s3_bucket" "bucket_green" {
  bucket = lower("${var.prefix}-${var.user_defined}-webapp-green")
  acl    = "private"

  website {
    index_document = "index.html"
  }

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Blue/Green S3 Bucket Policies
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "bucket_policy_blue" {
    bucket = aws_s3_bucket.bucket_blue.id
    policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForPublicWebsiteContent"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = {
          "AWS": aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket_blue.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_policy" "bucket_policy_green" {
    bucket = aws_s3_bucket.bucket_green.id
    policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForPublicWebsiteContent"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = {
          "AWS": aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket_green.arn}/*"
      },
    ]
  })
}