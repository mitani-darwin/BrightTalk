#!/bin/bash

# Docker Hubログインスクリプト
# 認証トークンの期限切れ対応（Docker Hub PAT を使用）

set -e

# 設定
REGISTRY="index.docker.io"

# 色付きログ
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Docker Hub ログイン実行
echo_warning "Docker Hub にログイン中..."
if echo "$DOCKER_HUB_PASSWORD" | docker login "$REGISTRY" --username "$DOCKER_HUB_USERNAME" --password-stdin; then
    echo_success "✅ Docker Hub ログイン成功"

    echo ""
    echo_warning "これで以下が可能になります："
    echo "• docker push index.docker.io/${DOCKER_HUB_USERNAME}/bright_talk:latest"
    echo "• kamal deploy"

else
    echo_error "❌ Docker Hub ログインに失敗しました"
    echo_error "DOCKER_HUB_USERNAME / DOCKER_HUB_PASSWORD を確認してください"
    exit 1
fi

