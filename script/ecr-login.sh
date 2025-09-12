#!/bin/bash

# ECR専用ログインスクリプト
# 認証トークンの期限切れ対応

set -e

# 設定
ECR_REGISTRY="017820660529.dkr.ecr.ap-northeast-1.amazonaws.com"
AWS_REGION="ap-northeast-1"

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

# ECRログイン実行
echo_warning "ECRにログイン中..."
if aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY; then
    echo_success "✅ ECRログイン成功"

    # 環境変数として設定（現在のシェルセッション用）
    export ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)
    echo_success "✅ ECR_PASSWORD環境変数を設定しました（12時間有効）"

    echo ""
    echo_warning "以下のコマンドでECR_PASSWORDを設定してください："
    echo "export ECR_PASSWORD=\$(aws ecr get-login-password --region $AWS_REGION)"
    echo ""
    echo_warning "これで以下が可能になります："
    echo "• docker push $ECR_REGISTRY/bright_talk"
    echo "• kamal deploy"

else
    echo_error "❌ ECRログインに失敗しました"
    echo_error "AWS認証情報を確認してください"
    exit 1
fi

