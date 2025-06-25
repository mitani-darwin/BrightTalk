output "nginx_security_group_id" {
  description = "ID of the Nginx security group"
  value       = aws_security_group.nginx.id
}