# Security Group Outputs
output "security_group_id" {
  description = "Security group ID for web server"
  value       = aws_security_group.web.id
}

output "security_group_name" {
  description = "Security group name"
  value       = aws_security_group.web.name
}