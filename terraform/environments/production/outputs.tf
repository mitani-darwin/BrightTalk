output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "public_subnet_id_2" {
  description = "ID of the second public subnet"
  value       = module.vpc.public_subnet_id_2
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "availability_zone" {
  description = "Availability zone used"
  value       = module.vpc.availability_zone
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance (Elastic IP)"
  value       = module.ec2.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = module.ec2.elastic_ip_allocation_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

# PC名とSSH鍵関連の出力値
output "pc_name" {
  description = "Automatically detected PC name"
  value       = module.ec2.pc_name
}

output "ssh_key_filename_for_kamal" {
  description = "SSH key filename for Kamal deploy.yml"
  value       = module.ec2.ssh_key_filename_for_kamal
}