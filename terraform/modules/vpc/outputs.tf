output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the first public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_id_2" {
  description = "ID of the second public subnet"
  value       = aws_subnet.public_2.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "availability_zone" {
  description = "Availability zone used for first subnet"
  value       = aws_subnet.public.availability_zone
}