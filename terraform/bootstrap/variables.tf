
# bootstrap環境では通常変数は不要ですが、
# エラーを避けるために基本的な変数を定義
variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "brighttalk"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "bootstrap"
}