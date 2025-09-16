#!/bin/bash
set -e

# ログファイルの設定
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "=========================================="
echo "Starting Docker installation: $(date)"
echo "=========================================="

# 環境変数の設定
export DEBIAN_FRONTEND=noninteractive

# システムアップデート
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# 必要なパッケージのインストール
echo "Installing required packages..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# Docker公式GPGキーを追加
echo "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Dockerリポジトリを追加
echo "Adding Docker repository..."
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# パッケージリストを更新
apt-get update -y

# Dockerをインストール
echo "Installing Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Dockerサービスの開始と有効化
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker

# ubuntuユーザーをdockerグループに追加
echo "Adding ubuntu user to docker group..."
usermod -aG docker ubuntu

# Docker Composeの最新版をインストール（念のため）
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# カスタムHTMLページの作成（一時的な確認用）
echo "Creating status page..."
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BrightTalk - Docker Server</title>
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
        <h1>🐳 BrightTalk Docker Server</h1>

        <div class="status">
            <span class="emoji">✅</span>
            <h2>Server Status: Docker Ready</h2>
            <p>Docker is installed and running!</p>
        </div>

        <div class="info">
            <h3>🚀 Server Information</h3>
            <p><strong>Environment:</strong> <span class="highlight">Production</span></p>
            <p><strong>Container Platform:</strong> <span class="highlight">Docker</span></p>
            <p><strong>Deployment Tool:</strong> <span class="highlight">Kamal</span></p>
            <p><strong>Server:</strong> <span class="highlight">Ubuntu + Docker</span></p>
            <p><strong>Deployment Time:</strong> <span class="highlight">$(date)</span></p>
        </div>

        <div class="info">
            <h3>🔧 Quick Status</h3>
            <p>• Docker Version: $(docker --version)</p>
            <p>• Docker Compose: $(docker-compose --version)</p>
            <p>• Ready for Kamal deployment</p>
        </div>
    </div>

    <!-- Nginx for temporary status serving -->
    <script>
        // Auto-refresh every 30 seconds
        setTimeout(() => location.reload(), 30000);
    </script>
</body>
</html>
HTML

# 一時的なWebサーバー（Nginxコンテナ）を起動してステータスページを提供
echo "Starting temporary status server..."
docker run -d \
  --name temp-status-server \
  --restart unless-stopped \
  -p 80:80 \
  -v /var/www/html:/usr/share/nginx/html:ro \
  nginx:alpine

# ファイアウォール設定
echo "Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# 動作確認
echo "Verifying Docker installation..."
docker --version
docker-compose --version
docker run hello-world

# システム情報を出力
echo "System status:"
echo "Docker active: $(systemctl is-active docker)"
echo "Docker enabled: $(systemctl is-enabled docker)"
echo "Docker containers:"
docker ps

# 最終メッセージ
echo "=========================================="
echo "Docker installation completed: $(date)"
echo "Server is ready for Kamal deployment"
echo "Temporary status server running on port 80"
echo "Log file: $LOG_FILE"
echo "=========================================="