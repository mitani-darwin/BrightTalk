output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

# HTTPS関連の出力を削除
# output "https_listener_arn" {
#   description = "ARN of the HTTPS listener"
#   value       = aws_lb_listener.https.arn
# }