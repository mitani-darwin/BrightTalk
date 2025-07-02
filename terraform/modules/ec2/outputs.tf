output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.web_server.public_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance (alias)"
  value       = aws_eip.web_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.pc_key.key_name
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = aws_eip.web_server.id
}

# PC名とSSH鍵関連の出力値
output "pc_name" {
  description = "Automatically detected PC name"
  value       = data.external.pc_name.result.pc_name
}

output "ssh_key_pair_name" {
  description = "Name of the generated SSH key pair"
  value       = aws_key_pair.pc_key.key_name
}

output "ssh_private_key_file" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}

output "ssh_public_key_file" {
  description = "Path to the public key file"
  value       = local_file.public_key.filename
}

output "ssh_key_filename_for_kamal" {
  description = "SSH key filename for Kamal deploy.yml"
  value       = "ssh-keys/${data.external.pc_name.result.pc_name}-ed25519-key"
}