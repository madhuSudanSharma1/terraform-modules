# Load Balancer Security Group
#  SG for LB
module "lb_security_group" {
  tags = var.tags
  source = "../security_group"

  security_group_name        = "${var.lb_name}-sg"
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

# Load Balancer
resource "aws_lb" "lb" {
  name               = var.lb_name
  internal           = var.internal
  load_balancer_type = var.lb_type
  subnets            = var.subnet_ids
  security_groups    = var.lb_type == "application" ? [module.lb_security_group.security_group_id] : null

  tags = merge(
    var.tags,
    {
      Name = "${var.lb_name}-${var.lb_type}"
    }
  )
}

# Target Groups
resource "aws_lb_target_group" "lb_target_group" {
  for_each = { for tg in var.lb_target_groups : tg.name => tg }

  name        = "${var.lb_name}-${each.value.name}-tg"
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = var.network_mode == "awsvpc" ? "ip" : "instance"

  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", null) != null ? [1] : []
    content {
      path                = lookup(each.value.health_check, "path", null)
      protocol            = lookup(each.value.health_check, "protocol", each.value.protocol)
      matcher             = lookup(each.value.health_check, "matcher", null)
      interval            = lookup(each.value.health_check, "interval", 30)
      timeout             = lookup(each.value.health_check, "timeout", 5)
      healthy_threshold   = lookup(each.value.health_check, "healthy_threshold", 2)
      unhealthy_threshold = lookup(each.value.health_check, "unhealthy_threshold", 2)
    }
  }

  tags = merge(var.tags, { Name = "${var.lb_name}-${each.value.name}-tg" })
}

# Listeners
resource "aws_lb_listener" "lb_listener" {
  for_each = { for listener in var.lb_listeners : listener.port => listener }

  load_balancer_arn = aws_lb.lb.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = lookup(each.value, "ssl_policy", null)
  certificate_arn   = lookup(each.value, "certificate_arn", null)

  dynamic "default_action" {
    for_each = each.value.default_actions
    content {
      type             = default_action.value.type
      target_group_arn = lookup(default_action.value, "target_group_arn", null)
      order            = lookup(default_action.value, "order", null)

      dynamic "redirect" {
        for_each = lookup(default_action.value, "redirect", null) != null ? [default_action.value.redirect] : []
        content {
          port        = lookup(redirect.value, "port", "443")
          protocol    = lookup(redirect.value, "protocol", "HTTPS")
          status_code = lookup(redirect.value, "status_code", "HTTP_301")
        }
      }

      dynamic "fixed_response" {
        for_each = lookup(default_action.value, "fixed_response", null) != null ? [default_action.value.fixed_response] : []
        content {
          content_type = lookup(fixed_response.value, "content_type", "text/plain")
          message_body = lookup(fixed_response.value, "message_body", "Default response")
          status_code  = lookup(fixed_response.value, "status_code", "404")
        }
      }
    }
  }
}

# Listener Rules (for ALB)
resource "aws_lb_listener_rule" "lb_listener_rule" {
  for_each = { for rule in var.lb_listener_rules : rule.priority => rule }

  listener_arn = aws_lb_listener.lb_listener[each.value.listener_port].arn
  priority     = each.value.priority

  action {
    type             = each.value.action_type
    target_group_arn = aws_lb_target_group.lb_target_group[each.value.target_group_name].arn
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      path_pattern {
        values = lookup(condition.value, "path_values", null)
      }
    }
  }
}
