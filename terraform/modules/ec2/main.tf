terraform {
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

# PC名をシェルから自動取得
data "external" "pc_name" {
  program = ["bash", "-c", "echo '{\"pc_name\":\"'$(hostname)'\"}'"]
}

# Ed25519 SSH鍵ペアを生成
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# AWS Key Pairリソースとして登録
resource "aws_key_pair" "pc_key" {
  key_name   = "${var.project_name}-${var.environment}-${data.external.pc_name.result.pc_name}"
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name        = "${var.project_name}-${var.environment}-${data.external.pc_name.result.pc_name}"
    Environment = var.environment
    Project     = var.project_name
    PCName      = data.external.pc_name.result.pc_name
  }
}

# ssh-keysディレクトリを作成
resource "local_file" "ssh_keys_directory" {
  content  = ""
  filename = "${path.root}/../../ssh-keys/.gitkeep"

  file_permission = "0644"
}

# Ed25519秘密鍵をssh-keysディレクトリに保存
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_openssh
  filename = "${path.root}/../../ssh-keys/${data.external.pc_name.result.pc_name}-ed25519-key"

  file_permission = "0600"

  depends_on = [local_file.ssh_keys_directory]
}

# Ed25519公開鍵をssh-keysディレクトリに保存
resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.root}/../../ssh-keys/${data.external.pc_name.result.pc_name}-ed25519-key.pub"

  file_permission = "0644"

  depends_on = [local_file.ssh_keys_directory]
}

# 最新のAmazon Linux 2 AMIを取得（ARM64対応）
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# SSM用のIAMロール
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-${var.environment}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SSM管理ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatchログ送信用ポリシー（オプション）
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAMインスタンスプロファイル
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-${var.environment}-ssm-profile"
  role = aws_iam_role.ssm_role.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-profile"
    Environment = var.environment
    Project     = var.project_name
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
  key_name               = aws_key_pair.pc_key.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data = templatefile("${path.module}/user_data.sh", {
    public_keys = [{
      name       = data.external.pc_name.result.pc_name
      public_key = tls_private_key.ssh_key.public_key_openssh
    }]
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