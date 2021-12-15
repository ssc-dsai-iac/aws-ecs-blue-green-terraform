variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used"
  type = string
  default = ""
}

variable "route_table_ids" {
  description = "The route table IDs to be used for the DynamoDB endpoint"
	type = list(string)
	default = []  
}

variable "tags" {
  description   = "A map of tags to add to all resources"
  type          = map(string)
  default       = {}
}