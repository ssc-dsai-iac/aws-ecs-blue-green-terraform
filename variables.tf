variable "cdxp_ip_set" {
  description = "A List of CDXP IPs to whitelist"
  type        = list(string)
  default = []
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR"
  type        = string
  default = "10.0.0.0/16"
}

variable "costcenter" {
  description = "cost center name to be used when tagging resources"
  type        = string
}

variable "env" {
  description = "Environment name to be used when tagging resources"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "prefix" {
  description = "A prefix used for all resources in this example"
  type        = string
}

variable "region" {
  description = "The AWS Region in which all resources in this example should be provisioned"
  type        = string
}

variable "ssn" {
  description = "ssn name to be used when tagging resources"
  type        = string
}

variable "subowner" {
  description = "subowner name to be used when tagging resources"
  type        = string
}

variable "user_defined" {
  description = "the name used for all resources in this example"
  type        = string
}