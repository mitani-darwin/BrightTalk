# New format variables (production and development)
variable "bucket_name_production" {
  description = "Name of the S3 bucket (production)"
  type        = string
  default     = null
}

variable "environment_production" {
  description = "Environment name (production)"
  type        = string
  default     = "production"
}

variable "ec2_role_name_production" {
  description = "Name of the existing EC2 IAM role to attach S3 policy to (production)"
  type        = string
  default     = null
}

variable "bucket_name_development" {
  description = "Name of the S3 bucket (development)"
  type        = string
  default     = null
}

variable "environment_development" {
  description = "Environment name (development)"
  type        = string
  default     = "development"
}

variable "ec2_role_name_development" {
  description = "Name of the existing EC2 IAM role to attach S3 policy to (development)"
  type        = string
  default     = null
}

# Legacy variables for backward compatibility (used by s3_db_backup module)
variable "bucket_name" {
  description = "Name of the S3 bucket (legacy format)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (legacy format)"
  type        = string
  default     = "production"
}

variable "ec2_role_name" {
  description = "Name of the existing EC2 IAM role to attach S3 policy to (legacy format)"
  type        = string
  default     = null
}