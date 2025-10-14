# Locals to determine deployment type
locals {
  is_single_az_instance  = var.deployment_type == "single-az-instance"
  is_multi_az_instance   = var.deployment_type == "multi-az-instance"
  is_multi_az_db_cluster = var.deployment_type == "multi-az-db-cluster"
}

# Data Source for VPC CIDR
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = var.kms_key_rotation_enabled
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kms-key"
  })
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/${var.name_prefix}-rds-key"
  target_key_id = aws_kms_key.rds_key.id
}

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${var.name_prefix}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "DB Subnet Group for ${var.name_prefix} RDS"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-subnet-group"
  })
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.name_prefix}-rds-sg-"
  description = "Allow inbound traffic to RDS from within VPC"
  vpc_id      = var.vpc_id

  # Ingress rule: Allow traffic from anywhere in the VPC to the RDS port
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    description = "Allow VPC traffic to RDS port"
  }

  # Egress rule: Allow outbound traffic to VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    description = "Allow all outbound traffic to VPC"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg"
  })
}

# RDS Cluster Parameter Group (only for Multi-AZ DB Clusters)
resource "aws_rds_cluster_parameter_group" "cluster_params" {
  count       = local.is_multi_az_db_cluster ? 1 : 0
  name_prefix = "${var.name_prefix}-cluster-pg-"
  family      = var.db_cluster_parameter_group_family
  description = "RDS Cluster Parameter Group for ${var.name_prefix} Multi-AZ DB Cluster"

  dynamic "parameter" {
    for_each = var.additional_cluster_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster-parameter-group"
  })
}

# RDS DB Parameter Group (for standard instances AND Multi-AZ DB Cluster instances)
resource "aws_db_parameter_group" "db_params" {
  name_prefix = "${var.name_prefix}-db-pg-"
  family      = var.db_parameter_group_family
  description = "RDS DB Parameter Group for ${var.name_prefix}"

  dynamic "parameter" {
    for_each = var.additional_db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-parameter-group"
  })
}

# Conditional Resources: Standard RDS Instance OR Multi-AZ DB Cluster


# Standard RDS Instance (Single-AZ or Classic Multi-AZ)
resource "aws_db_instance" "db_instance" {
  count = local.is_single_az_instance || local.is_multi_az_instance ? 1 : 0

  identifier                            = var.name_prefix
  db_name                               = var.database_name
  engine                                = var.engine_type
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  allocated_storage                     = var.allocated_storage
  storage_type                          = var.storage_type
  username                              = var.master_username
  password                              = var.master_password
  vpc_security_group_ids                = [aws_security_group.rds_sg.id]
  db_subnet_group_name                  = aws_db_subnet_group.db_subnet_group.name
  multi_az                              = local.is_multi_az_instance # True if multi-az-instance, false if single-az-instance
  publicly_accessible                   = var.publicly_accessible
  skip_final_snapshot                   = var.skip_final_snapshot
  backup_retention_period               = var.backup_retention_period
  kms_key_id                            = aws_kms_key.rds_key.arn
  storage_encrypted                     = var.storage_encrypted
  apply_immediately                     = var.apply_immediately
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  parameter_group_name                  = aws_db_parameter_group.db_params.name
  iam_database_authentication_enabled   = var.iam_database_authentication
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = var.performance_insights_enabled ? aws_kms_key.rds_key.arn : null
  # manage_master_user_password           = var.manage_master_user_password
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-instance"
  })
}

# Multi-AZ DB Cluster (for standard engines)
resource "aws_rds_cluster" "multi_az_cluster" {
  count = local.is_multi_az_db_cluster ? 1 : 0

  cluster_identifier              = var.name_prefix
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  engine                          = var.engine_type # Use standard engine here for Multi-AZ DB Cluster
  engine_version                  = var.engine_version
  port                            = var.port
  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  skip_final_snapshot             = var.skip_final_snapshot
  backup_retention_period         = var.backup_retention_period
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = aws_kms_key.rds_key.arn
  apply_immediately               = var.apply_immediately
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_params[0].name
  # Multi-AZ is inherent for aws_rds_cluster (for standard engines) when multiple instances are specified
  storage_type                          = var.storage_type
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = var.performance_insights_enabled ? aws_kms_key.rds_key.arn : null
  iam_database_authentication_enabled   = var.iam_database_authentication
  # manage_master_user_password           = var.manage_master_user_password
  allocated_storage         = var.allocated_storage
  db_cluster_instance_class = var.instance_class
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-multi-az-db-cluster"
  })
}

