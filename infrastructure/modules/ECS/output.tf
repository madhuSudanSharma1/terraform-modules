output "lb_id" {
  value       = module.load_balancer[0].lb_id
  description = "ID of the load balancer"
}

output "lb_arn" {
  value       = module.load_balancer[0].lb_arn
  description = "ARN of the load balancer"
}

output "lb_dns_name" {
  value       = module.load_balancer[0].lb_dns_name
  description = "DNS name of the load balancer"
}

output "lb_target_group_arns" {
  value       = module.load_balancer[0].lb_target_group_arns
  description = "Target group ARNs"
}

output "lb_listener_arns" {
  value       = module.load_balancer[0].lb_listener_arns
  description = "Listener ARNs"
}
