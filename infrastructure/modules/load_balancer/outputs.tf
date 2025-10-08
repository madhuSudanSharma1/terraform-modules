
output "lb_id" {
  description = "ID of the load balancer"
  value       = aws_lb.lb.id
}

output "lb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.lb.arn
}

output "lb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.lb.dns_name
}

output "lb_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.lb.zone_id
}

output "lb_target_group_arns" {
  description = "ARNs of all target groups"
  value       = { for k, v in aws_lb_target_group.lb_target_group : k => v.arn }
}

output "lb_target_group_names" {
  description = "Names of all target groups"
  value       = { for k, v in aws_lb_target_group.lb_target_group : k => v.name }
}

output "lb_listener_arns" {
  description = "ARNs of all listeners"
  value       = { for k, v in aws_lb_listener.lb_listener : k => v.arn }
}

output "lb_listener_rule_arns" {
  description = "ARNs of all listener rules"
  value       = { for k, v in aws_lb_listener_rule.lb_listener_rule : k => v.arn }
}
