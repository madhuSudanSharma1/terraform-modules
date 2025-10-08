aws_region         = "us-east-1"
vpc_name           = "madhu"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.0.1.0/24", "10.0.3.0/24"]
private_subnets    = ["10.0.2.0/24", "10.0.4.0/24"]
secondary_cidr     = null
tags = {
  Environment = "dev"
  Project     = "modular-infra"
}
nat_type = "gateway"
route_entries = {
  public = [
    { cidr = "0.0.0.0/0" }
  ]
  private = [
    { cidr = "0.0.0.0/0" }
  ]
}
nat_ami = "ami-024cf76afbc833688" # in us east 1
# nat_ami = "ami-056d6c2cc103e038c" # in us east 2
normal_ami = "ami-08982f1c5bf93d976" # in us east 1
# normal_ami = "ami-0ca4d5db4872d0c28" # in us east 2

# Load balancer configuration
lb_config = {
  lb_listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_actions = [
        {
          type = "fixed-response"
          order = 1
          fixed_response = {
            content_type = "text/plain"
            message_body = "Default response from LB"
            status_code  = "200"
          }
        }
      ]
    }
  ]

  lb_target_groups = [
    {
      name     = "frontend"
      port     = 80
      protocol = "HTTP"
      health_check = {
        path = "/"
      }
    }
  ]

  lb_listener_rules = [
    {
      listener_port     = 80
      priority          = 1
      target_group_name = "frontend"
      action_type       = "forward"
      conditions = [
        {
          path_values = ["/","/backend"]
        }
      ]
    }
  ]
}
