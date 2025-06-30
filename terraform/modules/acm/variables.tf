variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Route53は使用しないため、この変数は不要だが互換性のため残す
variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS validation (not used)"
  type        = string
  default     = null
}