# ---------------------------------------------------------------------------------------------------------------------
# Supporting Data
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
