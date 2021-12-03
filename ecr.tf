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