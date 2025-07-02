
# 最新のAmazon Linux 2 AMIを取得
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 公開鍵のバリデーション
locals {
  valid_public_keys = [
    for key in var.public_keys : {
      name       = key.name
      public_key = trimspace(key.public_key)
    }
    if key.public_key != "" &&
    key.public_key != null &&
    (startswith(trimspace(key.public_key), "ssh-rsa ") ||
    startswith(trimspace(key.public_key), "ssh-ed25519 ") ||
    startswith(trimspace(key.public_key), "ssh-dss ") ||
    startswith(trimspace(key.public_key), "ecdsa-sha2-"))
  ]
}

# 複数ユーザー用の公開鍵をキーペアとして作成
resource "aws_key_pair" "user_keys" {
  for_each = {
    for key in local.valid_public_keys : key.name => key
  }

  key_name   = "${var.project_name}-${var.environment}-${each.value.name}"
  public_key = each.value.public_key

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.value.name}"
    Environment = var.environment
    Project     = var.project_name
    User        = each.value.name
  }
}

# Elastic IPの作成
resource "aws_eip" "web_server" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2インスタンスの作成
resource "aws_instance" "web_server" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  # 複数ユーザー対応のユーザーデータスクリプト
  user_data = templatefile("${path.module}/user_data.sh", {
    public_keys = local.valid_public_keys
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-web"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IPの関連付け
resource "aws_eip_association" "web_server" {
  instance_id   = aws_instance.web_server.id
  allocation_id = aws_eip.web_server.id
}