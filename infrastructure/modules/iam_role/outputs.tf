output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.iam_role.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.iam_role.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.instance_profile[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.instance_profile[0].name : null
}