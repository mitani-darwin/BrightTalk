# PC名をシェルから自動取得
data "external" "pc_name" {
  program = ["bash", "-c", "echo '{\"pc_name\":\"'$(hostname)'\"}'"]
}

# Ed25519 SSH鍵ペアを生成（最も強固なアルゴリズム）
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# AWS Key Pairリソースとして登録（PC名ベース）
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

# ssh-keysディレクトリを作成（プロジェクトルートに配置）
resource "local_file" "ssh_keys_directory" {
  content  = ""
  filename = "${path.root}/../../ssh-keys/.gitkeep"

  file_permission = "0644"
}

# Ed25519秘密鍵をssh-keysディレクトリに保存（PC名を自動取得）
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_openssh
  filename = "${path.root}/../../ssh-keys/${data.external.pc_name.result.pc_name}-ed25519-key"

  file_permission = "0600"

  depends_on = [local_file.ssh_keys_directory]
}

# Ed25519公開鍵をssh-keysディレクトリに保存（PC名を自動取得）
resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.root}/../../ssh-keys/${data.external.pc_name.result.pc_name}-ed25519-key.pub"

  file_permission = "0644"

  depends_on = [local_file.ssh_keys_directory]
}

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

# Elastic IPの作成
resource "aws_eip" "web_server" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2インスタンスの作成（1つのみ）
resource "aws_instance" "web_server" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.pc_key.key_name  # PC名ベースのキーを使用
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  # PC名ベースのユーザーのみを作成
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