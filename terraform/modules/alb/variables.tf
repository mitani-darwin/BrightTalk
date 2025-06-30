
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "target_instance_id" {
  description = "EC2 instance ID to attach to target group"
  type        = string
}

# certificate_arn変数を削除
# variable "certificate_arn" {
#   description = "ARN of the SSL certificate"
#   type        = string
# }