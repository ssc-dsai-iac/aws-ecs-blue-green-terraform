#TODO: Add Security groups, add task execution role and task role

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