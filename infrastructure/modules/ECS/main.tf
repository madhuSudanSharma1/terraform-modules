# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}

# ECS Cluster Logging
resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/aws/ecs/cluster/${var.cluster_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

# EC2 Launch Type

# ECS-optimized AMI
data "aws_ami" "ecs" {
  count       = var.launch_type == "EC2" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}


# Launch Template
resource "aws_launch_template" "ecs" {
  count = var.launch_type == "EC2" ? 1 : 0

  name_prefix   = "${var.cluster_name}-ecs-"
  image_id      = data.aws_ami.ecs[0].id
  instance_type = var.ec2_instance_type

  vpc_security_group_ids = [module.ec2_security_group[0].security_group_id]

  iam_instance_profile {
    name = module.ecs_instance_role[0].instance_profile_name
  }

  user_data = base64encode(
    <<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
      EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.ec2_root_volume_size
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-ecs-instance"
    })
  }

  tags = var.tags
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs" {
  count            = var.launch_type == "EC2" ? 1 : 0
  name             = "${var.cluster_name}-ecs-asg"
  desired_capacity = var.ec2_desired_capacity
  max_size         = var.ec2_max_size
  min_size         = var.ec2_min_size
  vpc_zone_identifier = [
    for az, subnet in var.subnets : subnet.private
    if subnet.private != null
  ] # subnets for EC2 instances
  health_check_type         = "EC2"
  health_check_grace_period = 300
  protect_from_scale_in     = true

  launch_template {
    id      = aws_launch_template.ecs[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = merge(
      var.tags,
      {
        "AmazonECSManaged" = "true"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

}

# EC2 Capacity Provider
resource "aws_ecs_capacity_provider" "ec2" {
  count = var.launch_type == "EC2" ? 1 : 0

  name = "${var.cluster_name}-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs[0].arn
    managed_termination_protection = "ENABLED"
  }

  tags = var.tags
}

# Attach Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = compact([
    var.launch_type == "FARGATE" ? "FARGATE" : null,
    var.launch_type == "FARGATE" ? "FARGATE_SPOT" : null,
    var.launch_type == "EC2" ? aws_ecs_capacity_provider.ec2[0].name : null
  ])

  default_capacity_provider_strategy {
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : aws_ecs_capacity_provider.ec2[0].name
    weight            = 1
  }
}

# Task Definitions for multiple services
resource "aws_ecs_task_definition" "ecs_task_definitions" {
  for_each = var.services

  family                   = each.value.task_family
  requires_compatibilities = [var.launch_type]
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : var.network_mode
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = module.ecs_task_execution_role.role_arn
  task_role_arn            = module.ecs_task_role.role_arn

  container_definitions = jsonencode(each.value.container_definitions)

  dynamic "runtime_platform" {
    for_each = var.launch_type == "FARGATE" ? [1] : []
    content {
      operating_system_family = "LINUX"
      cpu_architecture        = "X86_64"
    }
  }

  tags = var.tags
}

# Load Balancer
module "load_balancer" {
  source  = "../LB"
  count   = var.load_balancer_config != null ? 1 : 0
  lb_name = "${var.cluster_name}-lb"
  subnet_ids = [
    for az, subnet in var.subnets : subnet.public
    if subnet.public != null
  ]
  vpc_id             = var.vpc_id
  tags               = var.tags
  security_group_ids = [module.lb_security_group[0].security_group_id]
  lb_listeners       = var.load_balancer_config.lb_listeners
  lb_target_groups   = var.load_balancer_config.lb_target_groups
  lb_listener_rules  = var.load_balancer_config.lb_listener_rules
  network_mode       = var.launch_type == "FARGATE" ? "awsvpc" : var.network_mode
}


# Service Connect 
## Namespace
resource "aws_service_discovery_private_dns_namespace" "service_connect_ns" {
  name = "${var.cluster_name}.local"
  vpc  = var.vpc_id
}


# Services for multiple applications
resource "aws_ecs_service" "ecs_services" {
  for_each = var.services

  name                 = "${var.cluster_name}-${each.key}"
  cluster              = aws_ecs_cluster.ecs_cluster.id
  task_definition      = aws_ecs_task_definition.ecs_task_definitions[each.key].arn
  desired_count        = each.value.desired_count
  launch_type          = var.launch_type
  force_new_deployment = true

  # Network configuration for awsvpc mode
  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" || var.launch_type == "FARGATE" ? [1] : []
    content {
      subnets = [
        for az, subnet in var.subnets : subnet.private
        if subnet.private != null
      ]
      security_groups = module.awsvpc_mode_security_group[0].security_group_id != null ? [module.awsvpc_mode_security_group[0].security_group_id] : []
      # assign_public_ip = var.fargate_assign_public_ip
    }
  }

  # Load balancer configuration
  dynamic "load_balancer" {
    for_each = each.value.load_balancer_config != null ? [each.value.load_balancer_config] : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  # Service connect configuration - FIXED
  dynamic "service_connect_configuration" {
    for_each = can(each.value.service_connect_configuration) ? [each.value.service_connect_configuration] : []
    content {
      enabled   = true
      namespace = aws_service_discovery_private_dns_namespace.service_connect_ns.arn

      dynamic "service" {
        for_each = try(service_connect_configuration.value.services, [])
        content {
          port_name      = service.value.port_name
          discovery_name = try(service.value.discovery_name, service.value.port_name)

          dynamic "client_alias" {
            for_each = try(service.value.client_alias, null) != null ? [service.value.client_alias] : []
            content {
              port     = client_alias.value.port
            }
          }
        }
      }
    }
  }

  tags = var.tags

  depends_on = [aws_ecs_cluster_capacity_providers.ecs_cluster_capacity_providers, module.load_balancer]
}
