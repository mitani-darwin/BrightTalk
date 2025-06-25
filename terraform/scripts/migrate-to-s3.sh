
#!/bin/bash
set -e

echo "=== Terraform Backend Fix Script ==="

# 1. Bootstrap環境でリソースを再作成
echo "1. Ensuring Bootstrap resources exist..."
cd terraform/bootstrap
terraform init
terraform apply -auto-approve

# リソース名を取得
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)

echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"

# 2. AWSでリソースが実際に存在するか確認
echo "2. Verifying AWS resources..."
aws s3 ls s3://$BUCKET_NAME > /dev/null && echo "✅ S3 bucket exists" || echo "❌ S3 bucket not found"
aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region ap-northeast-1 > /dev/null && echo "✅ DynamoDB table exists" || echo "❌ DynamoDB table not found"

# 3. 各環境を修復
echo "3. Fixing environment configurations..."
cd ../environments

for env in development production staging; do
    echo "Fixing $env environment..."
    cd $env

    # main.tfの内容を修正
    sed -i.bak "s/bucket.*=.*\".*\"/bucket         = \"$BUCKET_NAME\"/g" main.tf
    sed -i '' "s/dynamodb_table.*=.*\".*\"/dynamodb_table = \"$DYNAMODB_TABLE\"/g" main.tf

    # .terraformディレクトリを削除
    rm -rf .terraform

    # 既存ローカルステートをバックアップ
    if [ -f terraform.tfstate ]; then
        cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
        echo "Local state backed up"
    fi

    # 初期化（最初はロック無効で試行）
    echo "Initializing $env environment..."
    if ! terraform init; then
        echo "Normal init failed, trying without lock..."
        terraform init -lock=false
    fi

    echo "$env environment fixed!"
    cd ..
done

echo "=== All environments fixed! ==="
echo ""
echo "Next steps:"
echo "1. cd terraform/environments/development && terraform plan"
echo "2. cd terraform/environments/production && terraform plan"
echo "3. cd terraform/environments/staging && terraform plan"