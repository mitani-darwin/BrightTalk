output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.web_server.public_ip
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.web_server.availability_zone
}

output "elastic_ip_id" {
  description = "ID of the Elastic IP"
  value       = aws_eip.web_server.id
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = aws_eip.web_server.allocation_id
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "key_pairs" {
  description = "Created key pairs for users"
  value = {
    for name, key_pair in aws_key_pair.user_keys : name => {
      key_name = key_pair.key_name
      fingerprint = key_pair.fingerprint
    }
  }
}

output "security_group_ids" {
  description = "Security group IDs attached to the instance"
  value       = aws_instance.web_server.vpc_security_group_ids
}

# デバッグ用：公開鍵の情報を出力
output "debug_public_keys" {
  description = "Debug information for public keys"
  value = {
    input_keys = var.public_keys
    valid_keys = local.valid_public_keys
  }
}