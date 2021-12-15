# ---------------------------------------------------------------------------------------------------------------------
# DynamoDB Temporary Table
# ---------------------------------------------------------------------------------------------------------------------
module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "1.1.0"
  
	name      = "temp-table"
  hash_key  = "id"
	range_key = "title"

	attributes = [
    {
      name = "id"
      type = "N"
    },
    {
      name = "title"
      type = "S"
    },
  ]

	tags = var.tags

}

# ---------------------------------------------------------------------------------------------------------------------
# VPC DynamoDB Gateway Endpoint
# ---------------------------------------------------------------------------------------------------------------------
module "vpc_endpoint" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = var.vpc_id

  endpoints = {
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = var.route_table_ids
      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
  }

  tags = var.tags

}

# ---------------------------------------------------------------------------------------------------------------------
# VPC DynamoDB Gateway Endpoint Supporting Data
# ---------------------------------------------------------------------------------------------------------------------
data "aws_vpc_endpoint_service" "dynamodb_vpce" {
  service = "dynamodb"

  filter {
    name   = "service-type"
    values = ["Gateway"]
  }
}


# data "aws_iam_role" "this" {
#   name = "ECSTaskRole"
# }

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    sid = "AccessFromSpecificEndpoint"
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"] #TODO: Explain in the doc that you can restrict to only one specific table once created.

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb_vpce.id]
    }
  }

  # statement {
  #   sid = "AccessFromEcsRole"
  #   effect = "Allow"
  #   actions   = ["*"]
  #   resources = ["*"]
  
  #   principals {
  #     type = "*"
  #     identifers = ["*"]
  #   }

  #   condition{
  #     test = "ArnEquals"
  #     variable = "aws:PrincipalArn"

  #     values = [data.aws_iam_role.this.arn]
  #   }
  # }
}