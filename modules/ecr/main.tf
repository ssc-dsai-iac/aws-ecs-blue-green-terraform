# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Registry (ECR)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  encryption_configuration {
    encryption_type = var.encryption_type == "KMS" ? var.encryption_type : "AES256"
    kms_key         = var.kms_key
  }

  image_scanning_configuration {
    scan_on_push = var.scan_images_on_push
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Create an IAM User for GitHub
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_user" "this" {
  name = "github-principal"
  tags = var.tags
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Registry (ECR) Policies
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "this" {
  statement {
    sid    = "GetAuthorizationToken"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [aws_iam_user.this.arn]
    }
    actions = [
      "ecr:GetAuthorizationToken"
    ]
  }

  statement {
    sid    = "AllowPull"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [aws_iam_user.this.arn]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }

  statement {
    sid    = "AllowPush"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [aws_iam_user.this.arn]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
  }
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.this.json
}


# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Registry (ECR) Lifecycle Policies
# ---------------------------------------------------------------------------------------------------------------------
locals {
  latest_image_rule = [{
    rulePriority = 10
    description = "For `latest` tag, keep latest image only"
    selection = {
      tagStatus = "tagged",
      tagPrefixList = ["latest"],
      countType = "imageCountMoreThan",
      countNumber = 2
    }
    action = { 
      type = "expire" 
    }
  }]

  untagged_image_rule = [{
    rulePriority = 20
    description  = "Remove untagged images"
    selection = {
      tagStatus   = "untagged"
      countType   = "imageCountMoreThan"
      countNumber = 1
    }
    action = {
      type = "expire"
    }
  }]

  remove_old_image_rule = [{
    rulePriority = 30
    description  = "Rotate images when reach ${var.max_image_count} images stored",
    selection = {
      tagStatus   = "any"
      countType   = "imageCountMoreThan"
      countNumber = var.max_image_count
    }
    action = {
      type = "expire"
    }
  }]
}

resource "aws_ecr_lifecycle_policy" "name" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = concat(local.latest_image_rule, local.untagged_image_rule, local.remove_old_image_rule)
  })
}