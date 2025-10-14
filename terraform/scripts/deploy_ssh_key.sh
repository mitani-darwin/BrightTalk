#!/bin/bash

# 公開鍵をサーバーに登録するヘルパースクリプト
# Usage: ./deploy_ssh_key.sh [key_name] [server_ip]

set -e

# 設定
SSH_KEY_DIR="~/.ssh"
DEFAULT_KEY_NAME="id_ed25519.pub"
SSH_KEY_TYPE="ed25519"
DEFAULT_SERVER="52.192.149.181"
SSH_PORT="47583"
SSH_USER="ec2-user"

# 引数の取得
KEY_NAME=${1:-$DEFAULT_KEY_NAME}
SERVER_IP=${2:-$DEFAULT_SERVER}
PUBLIC_KEY_PATH="${SSH_KEY_DIR}/${KEY_NAME}"

echo "🚀 公開鍵をサーバーに登録します..."
echo "キー: $PUBLIC_KEY_PATH"
echo "サーバー: $SSH_USER@$SERVER_IP:$SSH_PORT"

# 公開鍵の存在確認
if [ ! -f "$PUBLIC_KEY_PATH" ]; then
    echo "❌ 公開鍵が見つかりません: $PUBLIC_KEY_PATH"
    echo "先に ./register_ssh_key.sh を実行してください。"
    exit 1
fi

# サーバーに公開鍵を登録
echo "📤 公開鍵をサーバーに送信しています..."
ssh-copy-id -i "$PUBLIC_KEY_PATH" -p "$SSH_PORT" "$SSH_USER@$SERVER_IP"

echo "✅ 公開鍵の登録が完了しました！"
echo ""
echo "🔧 接続テスト:"
echo "ssh -i ${SSH_KEY_DIR}/${KEY_NAME}-${SSH_KEY_TYPE}-key -p $SSH_PORT $SSH_USER@$SERVER_IP"