variable "prefix" {
  description = "A prefix used for all resources in this example"
  type        = string
  default = ""
}
variable "user_defined" {
  description = "the name used for all resources in this example"
  type        = string
}

variable "vpc_id" {
  description = "ID of the associated Virtual Private Cloud"
  type = string
  default = ""
}

variable "subnets" {
  description = "List of subnets to associate with the Application Load Balancer"
  type = list(string)
  default = []
}

variable "tags" {
  description   = "A map of tags to add to all resources"
  type          = map(string)
  default       = {}
}