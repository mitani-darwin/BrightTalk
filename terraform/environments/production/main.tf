# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment
  project_name = var.project_name
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
}

# Security Groups Module
module "security" {
  source = "../../modules/security"

  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
}

# EC2 Module（PC名ベースのSSH鍵対応、単一インスタンス）
module "ec2" {
  source = "../../modules/ec2"

  environment        = var.environment
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_id
  security_group_ids = [module.security.web_security_group_id]
  instance_type     = var.instance_type
  # key_nameとpublic_keysパラメータを削除
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = [module.vpc.public_subnet_id, module.vpc.public_subnet_id_2]
  security_group_id = module.security.alb_security_group_id
  target_instance_id = module.ec2.instance_id
}