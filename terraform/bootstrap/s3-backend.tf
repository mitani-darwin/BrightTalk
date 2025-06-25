# S3バックエンド用のリソースを作成
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# バケット名用のランダム文字列
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Terraformステート用S3バケット
resource "aws_s3_bucket" "terraform_state" {
  bucket = "brighttalk-terraform-state-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "shared"
    Project     = "BrightTalk"
  }
}

# バケットのバージョニングを有効化
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# バケットの暗号化を有効化
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# パブリックアクセスをブロック
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ステートロック用DynamoDBテーブル
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "brighttalk-terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "shared"
    Project     = "BrightTalk"
  }
}

# 出力
output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
  description = "Name of the S3 bucket for Terraform state"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_state_lock.name
  description = "Name of the DynamoDB table for state locking"
}

output "aws_region" {
  value = "ap-northeast-1"
  description = "AWS region for the backend"
}