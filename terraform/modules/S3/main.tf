# 本番環境用のリソース
resource "aws_s3_bucket" "image_storage_production" {
  count  = var.bucket_name_production != null ? 1 : 0
  bucket = var.bucket_name_production

  tags = {
    Name        = "BrightTalk Image Storage Production"
    Environment = var.environment_production
  }
}

# 本番環境用S3バケットのCORS設定
resource "aws_s3_bucket_cors_configuration" "image_storage_production_cors" {
  count  = var.bucket_name_production != null ? 1 : 0
  bucket = aws_s3_bucket.image_storage_production[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_iam_policy" "s3_access_policy_production" {
  count       = var.bucket_name_production != null ? 1 : 0
  name        = "${var.environment_production}-${var.bucket_name_production}-s3-access-policy"
  description = "Policy for EC2 instances to access S3 bucket (Production)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.image_storage_production[0].arn,
          "${aws_s3_bucket.image_storage_production[0].arn}/*"
        ]
      }
    ]
  })
}

# 開発環境用のリソース
resource "aws_s3_bucket" "image_storage_development" {
  count  = var.bucket_name_development != null ? 1 : 0
  bucket = var.bucket_name_development

  tags = {
    Name        = "BrightTalk Image Storage Development"
    Environment = var.environment_development
  }
}

# 開発環境用S3バケットのCORS設定
resource "aws_s3_bucket_cors_configuration" "image_storage_development_cors" {
  count  = var.bucket_name_development != null ? 1 : 0
  bucket = aws_s3_bucket.image_storage_development[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_iam_policy" "s3_access_policy_development" {
  count       = var.bucket_name_development != null ? 1 : 0
  name        = "${var.environment_development}-${var.bucket_name_development}-s3-access-policy"
  description = "Policy for EC2 instances to access S3 bucket (Development)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.image_storage_development[0].arn,
          "${aws_s3_bucket.image_storage_development[0].arn}/*"
        ]
      }
    ]
  })
}

# レガシーリソース（後方互換性のため）
resource "aws_s3_bucket" "image_storage" {
  count         = var.bucket_name != null ? 1 : 0
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = "BrightTalk Image Storage"
    Environment = var.environment
  }
}

# レガシーS3バケットのCORS設定
resource "aws_s3_bucket_cors_configuration" "image_storage_cors" {
  count  = var.bucket_name != null ? 1 : 0
  bucket = aws_s3_bucket.image_storage[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  count       = var.bucket_name != null ? 1 : 0
  name        = "${var.environment}-${var.bucket_name}-s3-access-policy"
  description = "Policy for EC2 instances to access S3 bucket (Legacy)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.image_storage[0].arn,
          "${aws_s3_bucket.image_storage[0].arn}/*"
        ]
      }
    ]
  })
}