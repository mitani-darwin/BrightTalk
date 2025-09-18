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

output "bucket_id_production" {
  description = "ID of the S3 bucket (production)"
  value       = var.bucket_name_production != null ? aws_s3_bucket.image_storage_production[0].id : null
}

output "bucket_domain_name_production" {
  description = "Domain name of the S3 bucket (production)"
  value       = var.bucket_name_production != null ? aws_s3_bucket.image_storage_production[0].bucket_domain_name : null
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

# JavaScript assets bucket outputs
output "javascript_bucket_name" {
  description = "Name of the JavaScript assets S3 bucket"
  value       = var.javascript_bucket_name != null ? aws_s3_bucket.javascript_assets[0].bucket : null
}

output "javascript_bucket_arn" {
  description = "ARN of the JavaScript assets S3 bucket"
  value       = var.javascript_bucket_name != null ? aws_s3_bucket.javascript_assets[0].arn : null
}

output "javascript_bucket_id" {
  description = "ID of the JavaScript assets S3 bucket"
  value       = var.javascript_bucket_name != null ? aws_s3_bucket.javascript_assets[0].id : null
}

output "javascript_bucket_domain_name" {
  description = "Domain name of the JavaScript assets S3 bucket"
  value       = var.javascript_bucket_name != null ? aws_s3_bucket.javascript_assets[0].bucket_domain_name : null
}

output "javascript_s3_access_policy_arn" {
  description = "ARN of the JavaScript assets S3 access policy"
  value       = var.javascript_bucket_name != null ? aws_iam_policy.javascript_s3_access_policy[0].arn : null
}

