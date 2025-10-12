variable "name_prefix" {
  description = "A prefix for all resources created by this module."
  type        = string
  default     = "madhu-rds"
}

variable "vpc_id" {
  description = "The ID of the VPC where the RDS will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the RDS will be launched. Must be at least 1 for instance, at least 2 for Multi-AZ instance and at least 3 for Multi-AZ DB Cluster."
  type        = list(string)
  validation {
    condition = (
      (var.deployment_type == "single-az-instance" && length(var.subnet_ids) >= 1) ||
      (var.deployment_type == "multi-az-instance" && length(var.subnet_ids) >= 2) ||
      (var.deployment_type == "multi-az-db-cluster" && length(var.subnet_ids) >= 3)
    )
    error_message = "Insufficient number of subnets provided for the selected deployment_type."
  }
}

variable "engine_type" {
  description = "The database engine (e.g., 'mysql', 'postgresql')."
  type        = string
  default     = "postgres"
}

variable "deployment_type" {
  description = "The type of RDS deployment: 'single-az-instance', 'multi-az-instance', or 'multi-az-db-cluster'."
  type        = string
  default     = "single-az-instance"
  validation {
    condition     = contains(["single-az-instance", "multi-az-instance", "multi-az-db-cluster"], var.deployment_type)
    error_message = "Invalid deployment_type. Must be 'single-az-instance', 'multi-az-instance', or 'multi-az-db-cluster'."
  }
}

variable "database_name" {
  description = "The name of the database to create."
  type        = string
  default     = "testdb"
}

variable "master_username" {
  description = "The username for the master database user."
  type        = string
  default     = "testadmin"
}

variable "master_password" {
  description = "The password for the master database user."
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "The engine version to use."
  type        = string
  default     = "17.4"
}

variable "instance_class" {
  description = "The instance type/class for the RDS instance or cluster instances. (e.g., db.t3.medium, db.m5.large)."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The amount of allocated storage in GiB for standard RDS instances. Not used for Multi-AZ DB Clusters."
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "The storage type for standard RDS instances ('gp2', 'gp3', 'io1'). Not used for Multi-AZ DB Clusters."
  type        = string
  default     = "gp3"
}

variable "publicly_accessible" {
  description = "Specifies whether the DB instance/cluster is publicly accessible. Defaults to false (private access)."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance/cluster is deleted. Set to false for production."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for. 0 disables backups for Multi-AZ DB Clusters."
  type        = number
  default     = 7
}

variable "port" {
  description = "The port on which the DB accepts connections."
  type        = number
  default     = 5432
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance/cluster is encrypted."
  type        = bool
  default     = true
}

variable "kms_key_rotation_enabled" {
  description = "Specifies whether automatic key rotation is enabled for the KMS key created by the module."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any modifications are applied immediately, or during the next maintenance window."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance/cluster instances during the maintenance window."
  type        = bool
  default     = true
}

variable "db_cluster_size" {
  description = "The number of RDS instances to create in a Multi-AZ DB Cluster (minimum 3, typically 3 for HA with 1 writer, 2 readers). Only applicable for 'multi-az-db-cluster' deployment_type."
  type        = number
  default     = 3
  validation {
    condition     = var.deployment_type != "multi-az-db-cluster" || var.db_cluster_size > 2
    error_message = "For 'multi-az-db-cluster' deployment, 'db_cluster_size' must be at least 3."
  }
}

variable "db_cluster_parameter_group_family" {
  description = "The DB cluster parameter group family (e.g., mysql8.0, postgres14). Only applicable for 'multi-az-db-cluster' deployment_type."
  type        = string
  default     = "postgres17"
}

variable "db_parameter_group_family" {
  description = "The DB parameter group family (e.g., mysql8.0, postgres14). This is used for standard instances AND for individual instances within a Multi-AZ DB Cluster."
  type        = string
  default     = "postgres17"
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data."
  type        = number
  default     = 7
}

variable "tags" {
  description = "A map of tags to assign to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "additional_db_parameters" {
  description = "A map of additional parameters to apply to the DB parameter group (for both instance and cluster instances)."
  type        = map(string)
  default     = {}
}

variable "additional_cluster_parameters" {
  description = "A map of additional parameters to apply to the RDS cluster parameter group (only for Multi-AZ DB Clusters)."
  type        = map(string)
  default     = {}
}

variable "iam_database_authentication" {
  description = "Specifies whether to enable IAM database authentication."
  type        = bool
  default     = true

}
variable "manage_master_user_password" {
  description = "Specifies whether to manage the master user password. Set to false if you want to manage it yourself else AWS will create a random password and store it in AWS Secrets Manager."
  type        = bool
  default     = false
  
}