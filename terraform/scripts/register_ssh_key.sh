#!/bin/bash

# SSHキーペア登録スクリプト
# Usage: ./register_ssh_key.sh [key_name]

set -e

# 設定
SSH_KEY_DIR="terraform/ssh-keys"
DEFAULT_KEY_NAME=$(hostname)
SSH_KEY_TYPE="ed25519"

# 引数から鍵名を取得（省略時はデフォルト値を使用）
KEY_NAME=${1:-$DEFAULT_KEY_NAME}
PRIVATE_KEY_PATH="${SSH_KEY_DIR}/${KEY_NAME}-${SSH_KEY_TYPE}-key"
PUBLIC_KEY_PATH="${SSH_KEY_DIR}/${KEY_NAME}-${SSH_KEY_TYPE}-key.pub"

echo "🔑 SSHキーペア登録スクリプトを開始します..."
echo "キー名: ${KEY_NAME}"
echo "キータイプ: ${SSH_KEY_TYPE}"

# SSH鍵ディレクトリの作成
if [ ! -d "$SSH_KEY_DIR" ]; then
    echo "📁 SSH鍵ディレクトリを作成しています: $SSH_KEY_DIR"
    mkdir -p "$SSH_KEY_DIR"
fi

# 既存の鍵をチェック
if [ -f "$PRIVATE_KEY_PATH" ] || [ -f "$PUBLIC_KEY_PATH" ]; then
    echo "⚠️  既存のSSH鍵が見つかりました。"
    echo "秘密鍵: $PRIVATE_KEY_PATH"
    echo "公開鍵: $PUBLIC_KEY_PATH"

    read -p "既存の鍵を上書きしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ キーの生成をキャンセルしました。"
        exit 1
    fi

    echo "🗑️  既存の鍵を削除しています..."
    rm -f "$PRIVATE_KEY_PATH" "$PUBLIC_KEY_PATH"
fi

# SSH鍵ペアの生成
echo "🔐 SSH鍵ペアを生成しています..."
ssh-keygen -t ed25519 -C "${KEY_NAME}@$(date +%Y%m%d)" -f "$PRIVATE_KEY_PATH" -N ""

# 鍵のパーミッション設定
echo "🔒 鍵のパーミッションを設定しています..."
chmod 600 "$PRIVATE_KEY_PATH"
chmod 644 "$PUBLIC_KEY_PATH"

# 結果の表示
echo ""
echo "✅ SSH鍵ペアの生成が完了しました！"
echo ""
echo "📋 生成されたファイル:"
echo "  秘密鍵: $PRIVATE_KEY_PATH"
echo "  公開鍵: $PUBLIC_KEY_PATH"
echo ""

# 公開鍵の内容を表示
echo "🔑 公開鍵の内容:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$PUBLIC_KEY_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# SSH接続テスト用のコマンドを表示
echo "🔧 次のステップ:"
echo "1. 上記の公開鍵をサーバーの ~/.ssh/authorized_keys に追加してください"
echo "2. SSH接続をテストしてください:"
echo "   ssh -i $PRIVATE_KEY_PATH -p 47583 ec2-user@3.115.45.181"
echo ""

# SSH configエントリの提案
echo "💡 ~/.ssh/config に以下のエントリを追加することをお勧めします:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Host brighttalk-prod"
echo "    HostName 3.115.45.181"
echo "    Port 47583"
echo "    User ec2-user"
echo "    IdentityFile $(pwd)/$PRIVATE_KEY_PATH"
echo "    IdentitiesOnly yes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🎉 SSHキーペアの登録が完了しました！"