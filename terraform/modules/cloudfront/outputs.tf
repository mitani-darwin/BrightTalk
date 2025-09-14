output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.video_distribution.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Hosted Zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.video_distribution.hosted_zone_id
}

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.video_distribution.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.video_distribution.arn
}

output "distribution_status" {
  description = "Current status of the CloudFront distribution"
  value       = aws_cloudfront_distribution.video_distribution.status
}

output "cloudfront_url" {
  description = "Full HTTPS URL for the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.video_distribution.domain_name}"
}