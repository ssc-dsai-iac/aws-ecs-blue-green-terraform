output "lb_arn" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.alb.lb_arn
}

output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = module.alb.target_group_arns
}