terraform {
  required_version = ">= 1.0"

  # S3バックエンド設定を追加
  backend "s3" {
    bucket         = "brighttalk-terraform-state-prod"
    key            = "production/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "brighttalk-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
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

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  security_group_ids = [module.security.security_group_id]
  subnet_id          = module.vpc.public_subnet_ids[0]
}

# S3 module for image storage
module "s3" {
  source = "../../modules/s3"

  bucket_name    = "brighttalk.jp-image"
  environment    = "production"
  ec2_role_name  = module.ec2.iam_role_name  # Use the actual IAM role name from EC2 module
}

# S3 module for database backup storage
module "s3_db_backup" {
  source = "../../modules/s3"

  bucket_name    = "brighttalk-db-backup"
  environment    = "production"
  ec2_role_name  = module.ec2.iam_role_name  # Use the actual IAM role name from EC2 module
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project_name    = var.project_name
  environment     = var.environment
  repository_name = "bright_talk"
  ec2_role_name   = module.ec2.iam_role_name
}