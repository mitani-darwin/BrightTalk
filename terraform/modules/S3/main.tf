# S3 Bucket for image storage
resource "aws_s3_bucket" "image_storage" {
  bucket = var.bucket_name

  tags = {
    Name        = "BrightTalk Image Storage"
    Environment = var.environment
  }
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "image_storage" {
  bucket = aws_s3_bucket.image_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "image_storage" {
  bucket = aws_s3_bucket.image_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "image_storage" {
  bucket = aws_s3_bucket.image_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Policy for EC2 instances to access S3
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.environment}-s3-access-policy"
  description = "Policy for EC2 instances to access S3 bucket"

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
          aws_s3_bucket.image_storage.arn,
          "${aws_s3_bucket.image_storage.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the existing SSM role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = var.ec2_role_name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}