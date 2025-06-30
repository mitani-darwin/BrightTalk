
# Project Configuration
variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "brighttalk"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair name for EC2 instance"
  type        = string
}

# Domain Configuration (ACM関連を削除)
# variable "domain_name" {
#   description = "Primary domain name for SSL certificate"
#   type        = string
# }

# variable "subject_alternative_names" {
#   description = "Additional domain names for SSL certificate"
#   type        = list(string)
#   default     = []
# }