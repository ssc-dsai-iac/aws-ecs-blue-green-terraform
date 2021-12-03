# ---------------------------------------------------------------------------------------------------------------------
# VPC
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