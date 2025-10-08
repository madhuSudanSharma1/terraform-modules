variable "cluster_name" {
  type        = string
  description = "ECS Cluster name"
}

variable "launch_type" {
  type        = string
  description = "ECS launch type: FARGATE | EC2 "
  default     = "FARGATE"
}

# Fargate networking
variable "subnets" {
  type        = any
  description = "Subnets of the VPC"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for EC2 launch type"
}

variable "ec2_min_size" {
  type    = number
  default = 1
}

variable "ec2_max_size" {
  type    = number
  default = 3
}

variable "ec2_desired_capacity" {
  type    = number
  default = 1
}

# Task definition
variable "ecs_task_cpu" {
  type    = string
  default = "256"
}

variable "ecs_task_memory" {
  type    = string
  default = "512"
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}


variable "fargate_assign_public_ip" {
  type        = bool
  default     = true
  description = "Whether to assign a public IP to Fargate tasks"
}
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}
variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}
variable "vpc_id" {
  description = "VPC ID where ECS cluster and tasks will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}
variable "task_role_policy_arns" {
  description = "List of IAM policy ARNs to attach to the ECS task role"
  type        = list(string)
  default     = []
}
variable "ec2_root_volume_size" {
  description = "Root volume size (in GB) for EC2 instances (if using EC2 launch type)"
  type        = number
  default     = 30
}
variable "network_mode" {
  description = "Network mode for ECS tasks (if using EC2 launch type)"
  type        = string
  default     = "awsvpc"
}
variable "ec2_target_capacity" {
  description = "Target capacity for EC2 instances in the ECS cluster (if using EC2 launch type)"
  type        = number
  default     = 80
}
variable "service_discovery_registry_arn" {
  type        = string
  default     = null
  description = "ARN of the service discovery registry (if using service discovery)"
}
variable "load_balancer_config" {
  description = "Load balancer configuration for the ECS service"
  type = object({
     lb_listeners = list(any)
      lb_target_groups = list(any)
      lb_listener_rules = list(any)
  })
  default = null # No load balancer by default
}

variable "capacity_provider_strategies" {
  description = "Capacity provider strategies for MIXED launch type"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = []
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent for ECS service deployments"
  type        = number
  default     = 50
}

variable "services" {
  description = "Map of services to create"
  type = map(object({
    task_family           = optional(string)
    container_definitions = any
    desired_count         = optional(number, 1)
    cpu                   = optional(string, "256")
    memory                = optional(string, "512")
    load_balancer_config = optional(object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    }))
    service_discovery_registry_arn = optional(string)
    service_connect_configuration = optional(object({
      namespace = optional(string)
      services = optional(list(object({
        port_name      = string
        discovery_name = optional(string)
        client_alias = optional(object({
          dns_name = optional(string)
          port     = number
        }))
      })), [])
    }))
  }))
  default = {}
}

