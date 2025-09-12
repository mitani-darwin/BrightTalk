#!/bin/bash

# 簡易デプロイスクリプト（開発者向け）
# ECR認証 + Kamalデプロイのみ

set -e

ECR_REGISTRY="017820660529.dkr.ecr.ap-northeast-1.amazonaws.com"
AWS_REGION="ap-northeast-1"

echo "🚀 簡易デプロイを開始..."

# ECRログイン
echo "ECRにログイン中..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# 環境変数設定
export ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)

# Kamalデプロイ
echo "Kamalでデプロイ中..."
kamal deploy

echo "✅ 簡易デプロイ完了！"