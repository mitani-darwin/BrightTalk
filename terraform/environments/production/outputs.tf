# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# Security Outputs
output "security_group_id" {
  description = "Security group ID"
  value       = module.security.security_group_id
}

# EC2 Outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = module.ec2.instance_public_ip
}

output "ssh_key_filename_for_kamal" {
  description = "SSH key filename for Kamal deploy.yml"
  value       = module.ec2.ssh_key_filename_for_kamal
}

output "pc_name" {
  description = "PC name used for key generation"
  value       = module.ec2.pc_name
}

# 接続情報（高セキュリティSSHポート）
output "connection_info" {
  description = "Connection information"
  value = {
    public_ip    = module.ec2.instance_public_ip
    ssh_command  = "ssh -p 47583 -i ${module.ec2.ssh_key_filename_for_kamal} ec2-user@${module.ec2.instance_public_ip}"
    domain       = var.domain_name
    ssh_port     = 47583
  }
}

output "ssh_connection_command" {
  description = "SSH connection command with obscured port"
  value       = "ssh -p 47583 -i ${module.ec2.ssh_key_filename_for_kamal} ec2-user@${module.ec2.instance_public_ip}"
}

# s3 outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for image storage"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for image storage"
  value       = module.s3.bucket_arn
}

# CloudFront outputs
output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name for video content"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL for video content"
  value       = module.cloudfront.cloudfront_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

# JavaScript CloudFront outputs
output "cloudfront_javascript_distribution_domain_name" {
  description = "CloudFront distribution domain name for JavaScript assets"
  value       = module.cloudfront_javascript.distribution_domain_name
}

output "cloudfront_javascript_distribution_url" {
  description = "CloudFront distribution URL for JavaScript assets"
  value       = module.cloudfront_javascript.cloudfront_url
}

output "s3_javascript_bucket_name" {
  description = "Name of the S3 bucket for JavaScript assets"
  value       = module.s3_javascript_assets.javascript_bucket_name
}

