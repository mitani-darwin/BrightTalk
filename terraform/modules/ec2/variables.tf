
variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the instance"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (optional, will use latest Amazon Linux if not specified)"
  type        = string
  default     = null
}

variable "instance_name" {
  description = "Custom name for the EC2 instance"
  type        = string
  default     = ""
}

variable "enable_elastic_ip" {
  description = "Whether to create and associate an Elastic IP"
  type        = bool
  default     = true
}