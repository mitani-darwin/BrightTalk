
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "brighttalk-terraform-state-y4trnpld"
    key            = "environments/production/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "brighttalk-terraform-state-lock"  # 修正: 正しいテーブル名
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
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "BrightTalk"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  environment = "production"
  vpc_cidr    = var.vpc_cidr
}

module "security" {
  source = "../../modules/security"

  environment = "production"
  vpc_id      = module.vpc.vpc_id
}

module "ec2" {
  source = "../../modules/ec2"

  environment         = "production"
  instance_type      = var.instance_type
  key_name           = var.key_name
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [module.security.nginx_security_group_id]
}