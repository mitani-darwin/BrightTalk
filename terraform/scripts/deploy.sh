#!/bin/bash

ENVIRONMENT=${1:-development}

if [ ! -d "terraform/environments/$ENVIRONMENT" ]; then
  echo "Environment $ENVIRONMENT does not exist"
  exit 1
fi

# shellcheck disable=SC2164
cd "terraform/environments/$ENVIRONMENT"

# 環境変数ファイルが存在する場合は読み込み
if [ -f ".env" ]; then
  echo "Loading environment variables from .env"
  # shellcheck disable=SC2046
  # shellcheck disable=SC2002
  export $(cat .env | grep -v '^#' | xargs)
fi

echo "Deploying to $ENVIRONMENT environment..."
echo "Using AWS Profile: ${AWS_PROFILE:-default}"
echo "Using AWS Region: ${AWS_DEFAULT_REGION:-ap-northeast-1}"

# AWS認証確認
aws sts get-caller-identity

# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
  echo "AWS authentication failed. Please check your credentials."
  exit 1
fi

# Initialize Terraform
terraform init

# Plan
terraform plan

# Ask for confirmation
read -p "Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  terraform apply
else
  echo "Deployment cancelled"
fi