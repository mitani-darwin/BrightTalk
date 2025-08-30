
# EC2 Instance Outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_eip.web_server.public_ip
}

output "instance_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.web_server.private_ip
}

output "instance_public_dns" {
  description = "EC2 instance public DNS"
  value       = aws_instance.web_server.public_dns
}

# SSH Key Outputs
output "ssh_key_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.pc_key.key_name
}

output "ssh_key_filename_for_kamal" {
  description = "SSH key filename for Kamal deploy.yml"
  value       = "ssh-keys/${data.external.pc_name.result.pc_name}-ed25519-key"
}

output "pc_name" {
  description = "PC name used for key generation"
  value       = data.external.pc_name.result.pc_name
}

# Elastic IP Outputs
output "eip_id" {
  description = "Elastic IP ID"
  value       = aws_eip.web_server.id
}

output "eip_public_ip" {
  description = "Elastic IP public IP"
  value       = aws_eip.web_server.public_ip
}

# IAM Role Outputs
output "iam_role_name" {
  description = "IAM role name for EC2 instance"
  value       = aws_iam_role.ssm_role.name
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.ssm_profile.name
}