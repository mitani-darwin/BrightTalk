# SSH用の秘密鍵を生成
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 生成した公開鍵でAWSキーペアを作成
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa.public_key_openssh

  tags = {
    Name = "${var.environment}-key-pair"
  }
}

# 秘密鍵をローカルに保存
resource "local_file" "private_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "${path.module}/../../../ssh-keys/${var.key_name}.pem"

  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/../../../ssh-keys/${var.key_name}.pem"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id             = var.subnet_id

  # user_dataを直接指定（base64encode不要）
  user_data = <<-EOF
#!/bin/bash
set -e

# ログファイルの設定
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "=========================================="
echo "Starting user-data script: $(date)"
echo "=========================================="

# 環境変数の設定
export DEBIAN_FRONTEND=noninteractive

# システムアップデート
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# 必要なパッケージのインストール
echo "Installing required packages..."
apt-get install -y curl wget unzip

# Nginxのインストール
echo "Installing Nginx..."
apt-get install -y nginx

# Nginxサービスの開始と有効化
echo "Starting Nginx service..."
systemctl stop nginx || true
systemctl start nginx
systemctl enable nginx

# Nginxの状態確認
echo "Checking Nginx status..."
systemctl status nginx --no-pager || true

# カスタムHTMLページの作成
echo "Creating custom HTML page..."
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BrightTalk - Nginx Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 30px;
        }
        .status {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            text-align: center;
        }
        .info {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .highlight {
            color: #007bff;
            font-weight: bold;
        }
        .emoji {
            font-size: 2em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 BrightTalk Nginx Server</h1>

        <div class="status">
            <span class="emoji">✅</span>
            <h2>Server Status: Active</h2>
            <p>Nginx is running successfully!</p>
        </div>

        <div class="info">
            <h3>📊 Server Information</h3>
            <p><strong>Environment:</strong> <span class="highlight">${var.environment}</span></p>
            <p><strong>Deployed with:</strong> <span class="highlight">Terraform</span></p>
            <p><strong>Server:</strong> <span class="highlight">Ubuntu + Nginx</span></p>
            <p><strong>IP Type:</strong> <span class="highlight">Elastic IP (Static)</span></p>
            <p><strong>Deployment Time:</strong> <span class="highlight">$(date)</span></p>
        </div>

        <div class="info">
            <h3>🔗 Quick Links</h3>
            <p>• <a href="/nginx_status" target="_blank">Nginx Status</a></p>
            <p>• Server logs available via SSH</p>
        </div>
    </div>
</body>
</html>
HTML

# Nginxの設定テスト
echo "Testing Nginx configuration..."
nginx -t

# Nginxを再起動
echo "Restarting Nginx..."
systemctl restart nginx

# ファイアウォール設定
echo "Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# 最終確認
echo "Final status checks..."
echo "Nginx active: $(systemctl is-active nginx)"
echo "Nginx enabled: $(systemctl is-enabled nginx)"

# ポート確認
echo "Checking open ports..."
netstat -tlnp | grep :80 || true

# 最終メッセージ
echo "=========================================="
echo "User-data script completed: $(date)"
echo "Nginx should be accessible via Elastic IP"
echo "Log file: $LOG_FILE"
echo "=========================================="

EOF

  # インスタンスの作成時にuser_dataを確実に実行するためのタグ
  user_data_replace_on_change = true

  tags = {
    Name = "${var.environment}-nginx-server"
  }
}

# Elastic IP アドレスを作成
resource "aws_eip" "nginx_eip" {
  instance = aws_instance.nginx.id
  domain   = "vpc"

  tags = {
    Name = "${var.environment}-nginx-eip"
  }

  # インスタンスが完全に起動してからEIPを関連付け
  depends_on = [aws_instance.nginx]
}