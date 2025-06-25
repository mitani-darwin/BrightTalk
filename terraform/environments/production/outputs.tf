output "nginx_web_url" {
  value = "http://${module.ec2.elastic_ip}"
  description = "URL to access the Nginx web server"
}

output "nginx_ssh_command" {
  value = "ssh -i ssh-keys/${var.key_name}.pem ubuntu@${module.ec2.elastic_ip}"
  description = "SSH command to connect to the Nginx server"
}

output "elastic_ip" {
  value = module.ec2.elastic_ip
  description = "Elastic IP address of the Nginx server"
}