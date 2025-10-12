output "db_endpoint" {
  description = "The primary connection endpoint of the deployed database (writer endpoint for Multi-AZ DB Cluster)."
  value = local.is_multi_az_db_cluster ? (length(aws_rds_cluster.multi_az_cluster) > 0 ? aws_rds_cluster.multi_az_cluster[0].endpoint : null) : (length(aws_db_instance.db_instance) > 0 ? aws_db_instance.db_instance[0].address : null)
}

output "db_reader_endpoint" {
  description = "The reader endpoint of the Multi-AZ DB Cluster. Null for single or Multi-AZ instance deployments."
  value = local.is_multi_az_db_cluster ? (length(aws_rds_cluster.multi_az_cluster) > 0 ? aws_rds_cluster.multi_az_cluster[0].reader_endpoint : null) : null
}

output "db_port" {
  description = "The port for the DB instance or cluster."
  value = local.is_multi_az_db_cluster ? (length(aws_rds_cluster.multi_az_cluster) > 0 ? aws_rds_cluster.multi_az_cluster[0].port : null) : (length(aws_db_instance.db_instance) > 0 ? aws_db_instance.db_instance[0].port : null)
}

output "db_arn" {
  description = "The ARN of the DB instance or cluster."
  value = local.is_multi_az_db_cluster ? (length(aws_rds_cluster.multi_az_cluster) > 0 ? aws_rds_cluster.multi_az_cluster[0].arn : null) : (length(aws_db_instance.db_instance) > 0 ? aws_db_instance.db_instance[0].arn : null)
}

output "db_master_username" {
  description = "The master username for the database."
  value = local.is_multi_az_db_cluster ? (length(aws_rds_cluster.multi_az_cluster) > 0 ? aws_rds_cluster.multi_az_cluster[0].master_username : null) : (length(aws_db_instance.db_instance) > 0 ? aws_db_instance.db_instance[0].username : null)
}

output "db_security_group_id" {
  description = "The ID of the security group attached to the RDS."
  value       = aws_security_group.rds_sg.id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for RDS encryption."
  value       = aws_kms_key.rds_key.arn
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group created by the module."
  value       = aws_db_subnet_group.db_subnet_group.name
}
