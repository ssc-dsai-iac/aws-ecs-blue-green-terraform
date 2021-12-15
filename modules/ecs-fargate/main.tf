# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = var.name

  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    iterator = strategy

    content {
      capacity_provider = strategy.value["capacity_provider"]
      weight            = lookup(strategy.value, "weight", null)
      base              = lookup(strategy.value, "base", null)
    }
  }

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}


# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS) Services
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  for_each = {for service in var.services:  service.name => service}

  name            = each.value.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.value.task_definition_index].arn
	launch_type 		= each.value.launch_type

  desired_count   = each.value.desired_count

  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent

  network_configuration {
    subnets = each.value.subnets
  }

	load_balancer {
		target_group_arn = each.value.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS) Task Definition
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  for_each = {for index, task_definition in var.task_definitions:  index => task_definition}
  family                   = each.value.name
  requires_compatibilities = ["FARGATE"]
	network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.exec_task_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
	
	#Temporary container definition to be overide by application's new container
  container_definitions    = jsonencode([
    {
      name      = var.container_name
      image     = "httpd"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
    }
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS) Task Role Policy
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    sid    = "DynamodbTableAccess"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role" "task_role" {
  name               = "ECSTaskRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}


resource "aws_iam_role_policy" "task_role_policy" {
  name   = "DynamodbTablePermissions"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_permissions.json
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic Container Services (ECS) Task Execution Role Policy
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "exec_task_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "exec_task_role" {
  name               = "ECSExecutionTaskRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "exec_task_role_policy" {
  name   = "ECSExecutionTaskRolePolicy"
  role   = aws_iam_role.exec_task_role.id
  policy = data.aws_iam_policy_document.exec_task_permissions.json
}