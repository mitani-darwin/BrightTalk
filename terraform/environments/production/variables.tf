
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
  default     = ""
}

# 複数ユーザー対応
variable "authorized_users" {
  description = "List of users with their SSH public keys"
  type = list(object({
    name       = string
    public_key = string
  }))
  default = []
}