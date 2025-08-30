variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "ec2_role_name" {
  description = "Name of the existing EC2 IAM role to attach S3 policy to"
  type        = string
}