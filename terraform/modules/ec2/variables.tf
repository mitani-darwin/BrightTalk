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

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# 複数のキーペアに対応
variable "key_names" {
  description = "List of AWS Key Pair names for EC2 instance access"
  type        = list(string)
  default     = []
}

# 後方互換性のため残す
variable "key_name" {
  description = "Primary AWS Key Pair name for EC2 instance"
  type        = string
  default     = ""
}

# ユーザーの公開鍵リスト
variable "public_keys" {
  description = "List of public keys for user access"
  type = list(object({
    name       = string
    public_key = string
  }))
  default = []
}