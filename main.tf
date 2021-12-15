# ---------------------------------------------------------------------------------------------------------------------
# Backend Section
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Virtual Private Cloud (VPC)
# ---------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name = "${var.prefix}-${var.user_defined}"
  cidr = var.cidr

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

	# Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []
  
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
# Application Load Balancer (ALB) with Target Groups
# ---------------------------------------------------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  prefix = var.prefix
  user_defined = var.user_defined
  vpc_id = module.vpc.vpc_id
  subnets = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DynamoDB
# ---------------------------------------------------------------------------------------------------------------------
module "dynamodb" {
  source = "./modules/dynamodb"

  vpc_id = module.vpc.vpc_id
  route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }

}


# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Registry (ECR)
# ---------------------------------------------------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"
  
  name = lower("${var.prefix}-${var.user_defined}-ecr")

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS)
# ---------------------------------------------------------------------------------------------------------------------
module "ecs" {
  source  = "./modules/ecs-fargate"

	name               = "${var.prefix}-${var.user_defined}-ecs-cluster"
  container_insights = true

  capacity_providers = ["FARGATE"]
  container_name = "api-container"
  container_port = 80

  dynamodb_table_arn = module.dynamodb.dynamodb_table_arn

  task_definitions = [
    {
      name = "api"
      cpu = 1024
      memory = 2048
    }
  ]

  services = [
    {
      name = "${var.prefix}-${var.user_defined}-blue-service"
      launch_type = "FARGATE"
      task_definition_index = 0
      desired_count = 2
      deployment_maximum_percent = 100
      deployment_minimum_healthy_percent = 0
      subnets = module.vpc.private_subnets
      target_group_arn = module.alb.target_group_arns[0]
    },
    {
      name = "${var.prefix}-${var.user_defined}-green-service"
      launch_type = "FARGATE"
      task_definition_index = 0
      desired_count = 2
      deployment_maximum_percent = 100
      deployment_minimum_healthy_percent = 0
      subnets = module.vpc.private_subnets
      target_group_arn = module.alb.target_group_arns[1]
    }
  ]

  tags = {
		Env = var.env
		CostCenter = var.costcenter
		SSN = var.ssn
		SubOwner = var.subowner
	}

}

# ---------------------------------------------------------------------------------------------------------------------
# AWS WAF V2 for ALB
# ---------------------------------------------------------------------------------------------------------------------
module "alb_waf" {
  source = "./modules/waf-alb"

  name = "${var.prefix}-${var.user_defined}-alb-waf"
  alb_arn = module.alb.lb_arn
  cdxp_ip_set = var.cdxp_ip_set

  tags = {
		Env = var.env
		CostCenter = var.costcenter
		SSN = var.ssn
		SubOwner = var.subowner
	}
}

# # ---------------------------------------------------------------------------------------------------------------------
# # Frontend Section
# # ---------------------------------------------------------------------------------------------------------------------

# # ---------------------------------------------------------------------------------------------------------------------
# # Cloudfront Origin Access Identity
# # ---------------------------------------------------------------------------------------------------------------------
# resource "aws_cloudfront_origin_access_identity" "oai" {
#   comment = "OAI for ${var.prefix}-${var.user_defined}-webapp"
# }

# # ---------------------------------------------------------------------------------------------------------------------
# # Blue/Green S3 Bucket Policies
# # ---------------------------------------------------------------------------------------------------------------------
# resource "aws_s3_bucket_policy" "bucket_policy_blue" {
#     bucket = aws_s3_bucket.bucket_blue.id
#     policy = jsonencode({
#     Version = "2008-10-17"
#     Id      = "PolicyForPublicWebsiteContent"
#     Statement = [
#       {
#         Sid       = "PublicReadGetObject"
#         Effect    = "Allow"
#         Principal = {
#           "AWS": aws_cloudfront_origin_access_identity.oai.iam_arn
#         }
#         Action    = "s3:GetObject"
#         Resource = "${aws_s3_bucket.bucket_blue.arn}/*"
#       },
#     ]
#   })

#   depends_on = [
#     aws_cloudfront_origin_access_identity.oai
#   ]
# }

# resource "aws_s3_bucket_policy" "bucket_policy_green" {
#     bucket = aws_s3_bucket.bucket_green.id
#     policy = jsonencode({
#     Version = "2008-10-17"
#     Id      = "PolicyForPublicWebsiteContent"
#     Statement = [
#       {
#         Sid       = "PublicReadGetObject"
#         Effect    = "Allow"
#         Principal = {
#           "AWS": aws_cloudfront_origin_access_identity.oai.iam_arn
#         }
#         Action    = "s3:GetObject"
#         Resource = "${aws_s3_bucket.bucket_green.arn}/*"
#       },
#     ]
#   })
  
#   depends_on = [
#     aws_cloudfront_origin_access_identity.oai
#   ]
# }

# # ---------------------------------------------------------------------------------------------------------------------
# # Blue/Green S3 Buckets
# # ---------------------------------------------------------------------------------------------------------------------
# resource "aws_s3_bucket" "bucket_blue" {
#   bucket = lower("${var.prefix}-${var.user_defined}-webapp-blue")
#   acl    = "private"

#   website {
#     index_document = "index.html"
#   }

#   tags = {
#     Env = var.env
#     CostCenter = var.costcenter
#     SSN = var.ssn
#     SubOwner = var.subowner
#   }
# }

# resource "aws_s3_bucket" "bucket_green" {
#   bucket = lower("${var.prefix}-${var.user_defined}-webapp-green")
#   acl    = "private"

#   website {
#     index_document = "index.html"
#   }

#   tags = {
#     Env = var.env
#     CostCenter = var.costcenter
#     SSN = var.ssn
#     SubOwner = var.subowner
#   }
# }

# # ---------------------------------------------------------------------------------------------------------------------
# # Cloudfront Distribution
# # ---------------------------------------------------------------------------------------------------------------------
# resource "aws_cloudfront_distribution" "this" {
#   origin {
#     domain_name = aws_s3_bucket.bucket_blue.bucket_regional_domain_name
#     origin_id   = aws_s3_bucket.bucket_blue.bucket_regional_domain_name

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
#     }
#   }

#   enabled               = true
#   is_ipv6_enabled       = true
#   default_root_object   = "index.html"
#   price_class           = "PriceClass_200"

#   tags = {
#     Env = var.env
#     CostCenter = var.costcenter
#     SSN = var.ssn
#     SubOwner = var.subowner
#   }


#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = aws_s3_bucket.bucket_blue.bucket_regional_domain_name

#     forwarded_values {
#       query_string = true
#       cookies {
#         forward = "none"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#     viewer_protocol_policy = "redirect-to-https"
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }
# }