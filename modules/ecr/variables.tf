variable "name" {
  description = "Name of the Image"
  type = string
  default = ""
}

variable "scan_images_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository (true) or not (false)"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "How many Docker Image versions AWS ECR will store"
  type        = number
  default     = 50
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE`"
  type        = string
  default     = "IMMUTABLE"
}

variable "protected_tags" {
  description = "Name of image tags prefixes that should not be destroyed. Useful if you tag images with names like `dev`, `staging`, and `prod`"
  type        = set(string)
  default     = []
}

variable "encryption_type" {
  description = "The encryption type to use for the repository. Valid values are AES256 or KMS. Defaults to AES256."
  type = string
  default = "AES256"
}

variable "kms_key" {
  description = "The ARN of the KMS key to use when encryption_type is KMS. If not specified, uses the default AWS managed key for ECR."
  type = string
  default = null
}

variable "tags" {
  description   = "A map of tags to add to all resources"
  type          = map(string)
  default       = {}
}