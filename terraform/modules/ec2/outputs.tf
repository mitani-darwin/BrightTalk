output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.nginx.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance (Dynamic)"
  value       = aws_instance.nginx.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address of the EC2 instance (Static)"
  value       = aws_eip.nginx_eip.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = aws_eip.nginx_eip.id
}

output "instance_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.nginx.public_dns
}

output "ssh_connection_command" {
  description = "SSH connection command"
  value       = "ssh -i ssh-keys/${var.key_name}.pem ubuntu@${aws_eip.nginx_eip.public_ip}"
}

output "web_url" {
  description = "Web URL to access the nginx server"
  value       = "http://${aws_eip.nginx_eip.public_ip}"
}