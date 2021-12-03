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