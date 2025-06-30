output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}

output "certificate_domain_validation_options" {
  description = "Domain validation options for manual DNS setup"
  value       = aws_acm_certificate.cert.domain_validation_options
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.cert.status
}

output "dns_validation_records" {
  description = "DNS validation records for manual configuration"
  value = {
    for domain, options in local.domain_validation_options : domain => {
      name  = options.name
      value = options.record
      type  = options.type
    }
  }
}

# Route53を使用しないため、未検証の証明書ARNを返す
output "validated_certificate_arn" {
  description = "ARN of the certificate (not auto-validated)"
  value       = aws_acm_certificate.cert.arn
}