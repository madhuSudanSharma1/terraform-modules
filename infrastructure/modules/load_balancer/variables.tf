variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "lb_type" {
  description = "Type of load balancer: 'application' or 'network'"
  type        = string
  default     = "application"
}

variable "internal" {
  description = "Whether the LB is internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the LB and target groups will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the LB"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all LB resources"
  type        = map(string)
  default     = {}
}

variable "lb_target_groups" {
  description = <<EOT
List of target groups for the LB.
Each target group object supports:
- name
- port
- protocol
- target_type (optional, default: ip)
- health_check (optional: path, protocol, matcher, interval, timeout, healthy_threshold, unhealthy_threshold)
EOT
  type = list(object({
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
  default = []
}


variable "lb_listeners" {
  description = <<EOT
List of LB listeners.
Each listener object supports:
- port
- protocol
- ssl_policy (optional)
- certificate_arn (optional)
- default_actions (list of actions: forward, redirect, fixed_response)
EOT
  type = list(object({
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
  }))
  default = []
}

variable "lb_listener_rules" {
  description = <<EOT
List of listener rules.
Each rule object supports:
- listener_port
- priority
- target_group_name
- action_type (forward/fixed-response/redirect)
- conditions (host_values, path_values)
EOT
  type = list(object({
    listener_port     = number
    priority          = number
    target_group_name = string
    action_type       = string
    conditions = list(object({
      host_values = optional(list(string))
      path_values = optional(list(string))
    }))
  }))
  default = []
}

variable "network_mode" {
  description = "Network mode for ECS tasks (if using EC2 launch type)"
  type        = string
  default     = "awsvpc"
}