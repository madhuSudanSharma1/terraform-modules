variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "my-vpc"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}
variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}
variable "secondary_cidr" {
  description = "Secondary CIDR block for the VPC (optional)"
  type        = string
  default     = null
}
variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "modular-infra"
  }
}
variable "nat_type" {
  description = "Type of NAT (gateway or instance)"
  type        = string
  default     = "gateway"
}
variable "route_entries" {
  description = "Routes grouped by route table type"
  type = object({
    public = optional(list(object({
      cidr             = string
      gateway_id       = optional(string)
      use_nat_gateway  = optional(bool, false)
      use_nat_instance = optional(bool, false)
    })), [])
    private = optional(list(object({
      cidr             = string
      gateway_id       = optional(string)
      use_nat_gateway  = optional(bool, false)
      use_nat_instance = optional(bool, false)
    })), [])
  })
  default = {
    public  = [{ cidr = "0.0.0.0/0" }]
    private = [{ cidr = "0.0.0.0/0", use_nat_gateway = true }]
  }
}
variable "nat_ami" {
  description = "AMI ID for NAT instance (if using instance)"
  type        = string
}
variable "normal_ami" {
  description = "AMI ID for normal EC2 instance"
  type        = string
}


variable "lb_config" {
  type = object({
    lb_listeners = list(object({
      port            = number
      protocol        = string
      ssl_policy      = optional(string)
      certificate_arn = optional(string)
      default_actions = list(object({
        type             = string
        target_group_arn = optional(string)
        order            = optional(number)
        redirect = optional(object({
          port        = optional(string, "443")
          protocol    = optional(string, "HTTPS")
          status_code = optional(string, "HTTP_301")
        }))
        fixed_response = optional(object({
          content_type = optional(string, "text/plain")
          message_body = optional(string, "Default response")
          status_code  = optional(string, "404")
        }))
      }))
    })),
    lb_listener_rules = list(object({
      listener_port     = number
      priority          = number
      target_group_name = string
      action_type       = string
      conditions = list(object({
        host_values = optional(list(string))
        path_values = optional(list(string))
      }))
    })),
    lb_target_groups = list(object({
      name        = string
      port        = number
      protocol    = string
      target_type = optional(string, "ip")
      health_check = optional(object({
        path                = optional(string)
        protocol            = optional(string)
        matcher             = optional(string)
        interval            = optional(number)
        timeout             = optional(number)
        healthy_threshold   = optional(number)
        unhealthy_threshold = optional(number)
      }))
    }))
  })
  description = "Load balancer configuration"
  default = null

}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "my-ecs-cluster"  
}

variable "ecs_launch_type" {
  description = "The launch type for ECS (EC2 or FARGATE)"
  type        = string
  default     = "EC2"  
}
variable "ec2_network_mode" {
  description = "The network mode for EC2 launch type (bridge, host, awsvpc, none)"
  type        = string
  default     = "bridge"  
}