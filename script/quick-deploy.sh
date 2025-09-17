#!/bin/bash

# 簡易デプロイスクリプト（開発者向け）
# Docker Hub ログイン + Kamalデプロイのみ

set -e

REGISTRY="index.docker.io"

echo "🚀 簡易デプロイを開始..."

# Docker Hub ログイン
echo "Docker Hub にログイン中..."
echo "$DOCKER_HUB_PASSWORD" | docker login "$REGISTRY" --username "$DOCKER_HUB_USERNAME" --password-stdin

# Kamalデプロイ
echo "Kamalでデプロイ中..."
kamal deploy

echo "✅ 簡易デプロイ完了！"