# Security Group for EC2 instances (EC2 Launch Type)
module "ec2_security_group" {
  count = var.launch_type == "EC2" ? 1 : 0

  source = "../security_group"

  security_group_name        = "${var.cluster_name}-ec2-sg"
  security_group_description = "Security group for ECS EC2 instances"
  vpc_id                     = var.vpc_id

  ingress_rules = [
    {
      description = "HTTP from ALB"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  egress_rules = [
    {
      description = "All outbound traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = var.tags
}

# Security Group for Fargate 
module "awsvpc_mode_security_group" {
  count = var.launch_type == "FARGATE" || var.network_mode == "awsvpc" ? 1 : 0

  source = "../security_group"

  security_group_name        = "${var.cluster_name}-fargate-sg"
  security_group_description = "Security group for ECS Fargate tasks"
  vpc_id                     = var.vpc_id

  ingress_rules = [
    {
      description = "HTTP from ALB"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from ALB"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = [var.vpc_cidr]
    }
  ]

  egress_rules = [
    {
      description = "All outbound traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = var.tags
}

# IAM Role for ECS EC2 instances
module "ecs_instance_role" {
  count = var.launch_type == "EC2" ? 1 : 0

  source = "../iam_role"

  role_name = "${var.cluster_name}-ec2-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]

  create_instance_profile = true

  tags = var.tags
}

# ECS Task Execution
module "ecs_task_execution_role" {
  source = "../iam_role"

  role_name = "${var.cluster_name}-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]

  create_instance_profile = false # Task execution roles don't need instance profiles

  tags = var.tags
}

# Task Role (for permission for application running in ECS)
module "ecs_task_role" {

  source = "../iam_role"

  role_name = "${var.cluster_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  policy_arns = var.task_role_policy_arns

  create_instance_profile = false

  tags = var.tags
}

#  SG for LB
module "lb_security_group" {
  count = var.load_balancer_config != null ? 1 : 0
  tags = var.tags
  source = "../security_group"

  security_group_name        = "${var.cluster_name}-lb-sg"
  security_group_description = "Security group for ECS Load Balancer"
  vpc_id                     = var.vpc_id

  ingress_rules = [
    {
      description = "HTTP from anywhere"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from anywhere"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      description = "All outbound traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}