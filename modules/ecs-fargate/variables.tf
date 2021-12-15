variable "name" {
  description = "Name to be used on all the resources as identifier, also the name of the ECS cluster"
  type        = string
  default     = null
}

variable "capacity_providers" {
  description = "List of short names of one or more capacity providers to associate with the cluster. Valid values also include FARGATE and FARGATE_SPOT."
  type        = list(string)
  default     = []
}

variable "container_name" {
  description = "Name of the container to associate"
  type = string
  default = ""
}

variable "container_port" {
  description = "Port of the container to associate"
  type = number
  default = 80
}

variable "default_capacity_provider_strategy" {
  description = "The capacity provider strategy to use by default for the cluster. Can be one or more."
  type        = list(map(any))
  default     = []
}

variable "dynamodb_table_arn" {
  description = "The arn of the dynamoDB table to allow access to"
  type = string
  default = ""
}

variable "container_insights" {
  description = "Controls if ECS Cluster has container insights enabled"
  type        = bool
  default     = false
}

variable "services" {
  description = "List of ECS Services to provide"
  type = list(object({
    name = string
    launch_type = string
    task_definition_index = number
    desired_count = number
    deployment_maximum_percent = number
    deployment_minimum_healthy_percent = number
    subnets = list(string)
    target_group_arn = string
  }))
  default = []
}

variable "task_definitions" {
  description = "List of ECS Task Definitions to provide"
  type = list(object({
    name = string
    cpu = number
    memory = number 
  }))
  default = []
}
variable "tags" {
  description = "A map of tags to add to ECS Cluster"
  type        = map(string)
  default     = {}
}