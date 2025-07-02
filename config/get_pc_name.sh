#!/bin/bash

# PC名を取得してKamalのdeploy.ymlを自動更新するスクリプト
PC_NAME=$(hostname)
DEPLOY_FILE="deploy.yml"

echo "Detected PC name: $PC_NAME"

# deploy.ymlのSSHキーパスを自動更新
if [ -f "$DEPLOY_FILE" ]; then
    # macOSとLinuxで異なるsedコマンドに対応
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|ssh-keys/.*-ed25519-key|ssh-keys/${PC_NAME}-ed25519-key|g" "$DEPLOY_FILE"
    else
        # Linux
        sed -i "s|ssh-keys/.*-ed25519-key|ssh-keys/${PC_NAME}-ed25519-key|g" "$DEPLOY_FILE"
    fi
    echo "Updated deploy.yml with PC name: $PC_NAME"
    echo "SSH key path: ssh-keys/${PC_NAME}-ed25519-key"
else
    echo "Error: deploy.yml not found"
    exit 1
fi

# Terraformでインフラを更新
echo "Running terraform init -upgrade..."
cd ../terraform/environments/production
terraform init -upgrade

echo "Running terraform apply..."
terraform apply -auto-approve

# 結果を表示
echo "===== 結果 ====="
echo "PC名: $(terraform output -raw pc_name 2>/dev/null || echo 'Not available')"
echo "SSH鍵ファイル: $(terraform output -raw ssh_key_filename_for_kamal 2>/dev/null || echo 'Not available')"
echo "サーバーIP: $(terraform output -raw instance_public_ip 2>/dev/null || echo 'Not available')"