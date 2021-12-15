variable "alb_arn" {
  description = "The Amazon Resource Name (ARN) of the resource to associate with the web ACL. This must be an ARN of an Application Load Balancer or an Amazon API Gateway stage."
  type = string
  default = ""
}

variable "cdxp_ip_set" {
  description = "A List of CDXP IPs to whitelist"
  type        = list(string)
  default = []
}

variable "name" {
  description = "A name of the WebACL."
  type = string
  default = ""
}


variable "tags" {
  description   = "A map of tags to add to all resources"
  type          = map(string)
  default       = {}
}