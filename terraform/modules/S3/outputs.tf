# Production environment outputs
output "bucket_name_production" {
  description = "Name of the S3 bucket (production)"
  value       = var.bucket_name_production != null ? aws_s3_bucket.image_storage_production[0].bucket : null
}

output "bucket_arn_production" {
  description = "ARN of the S3 bucket (production)"
  value       = var.bucket_name_production != null ? aws_s3_bucket.image_storage_production[0].arn : null
}

output "s3_access_policy_arn_production" {
  description = "ARN of the S3 access policy (production)"
  value       = var.bucket_name_production != null ? aws_iam_policy.s3_access_policy_production[0].arn : null
}

# Development environment outputs
output "bucket_name_development" {
  description = "Name of the S3 bucket (development)"
  value       = var.bucket_name_development != null ? aws_s3_bucket.image_storage_development[0].bucket : null
}

output "bucket_arn_development" {
  description = "ARN of the S3 bucket (development)"
  value       = var.bucket_name_development != null ? aws_s3_bucket.image_storage_development[0].arn : null
}

output "s3_access_policy_arn_development" {
  description = "ARN of the S3 access policy (development)"
  value       = var.bucket_name_development != null ? aws_iam_policy.s3_access_policy_development[0].arn : null
}

# Legacy outputs for backward compatibility
output "bucket_name" {
  description = "Name of the S3 bucket (legacy)"
  value = var.bucket_name != null ? aws_s3_bucket.image_storage[0].bucket : null
}

output "bucket_arn" {
  description = "ARN of the S3 bucket (legacy)"
  value = var.bucket_name != null ? aws_s3_bucket.image_storage[0].arn : null
}

output "s3_access_policy_arn" {
  description = "ARN of the S3 access policy (legacy)"
  value = var.bucket_name != null ? aws_iam_policy.s3_access_policy[0].arn : null
}