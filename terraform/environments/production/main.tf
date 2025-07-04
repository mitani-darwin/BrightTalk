# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  project_name        = var.project_name
  environment         = var.environment
  instance_type       = var.instance_type
  security_group_ids  = [module.security.security_group_id]
  subnet_id           = module.vpc.public_subnet_id
}

# ACM Module (Let's Encryptを使用するため無効化)
# module "acm" {
#   source = "../../modules/acm"
#
#   project_name = var.project_name
#   environment  = var.environment
#   domain_name  = var.domain_name
# }