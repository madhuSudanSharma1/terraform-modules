provider "aws" {
  region = var.aws_region
}


# VPC
module "vpc" {
  source               = "./modules/vpc"
  name                 = var.vpc_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.availability_zones
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
  route_entries        = var.route_entries
  nat_type             = var.nat_type
  nat_ami              = var.nat_ami
  nat_instance_type    = "t2.micro"
}

# Load Balancer
# module "load_balancer" {
#   source  = "./modules/load_balancer"
#   count   = var.lb_config != null ? 1 : 0
#   lb_name = "${var.ecs_cluster_name}-lb"
#   subnet_ids = [
#     for az, subnet in module.vpc.subnet_ids_by_az : subnet.public
#     if subnet.public != null
#   ]
#   vpc_id             = module.vpc.vpc_id
#   lb_listeners       = var.lb_config.lb_listeners
#   lb_target_groups   = var.lb_config.lb_target_groups
#   lb_listener_rules  = var.lb_config.lb_listener_rules
#   network_mode       = var.ecs_launch_type == "FARGATE" ? "awsvpc" : var.ec2_network_mode
# }

# module "ecs" {
#   source               = "./modules/ecs"
#   cluster_name         = var.ecs_cluster_name
#   launch_type          = var.ecs_launch_type
#   subnets              = module.vpc.subnet_ids_by_az
#   vpc_id               = module.vpc.vpc_id
#   network_mode         = var.ec2_network_mode
#   vpc_cidr             = module.vpc.vpc_cidr_block
#   aws_region          = var.aws_region
#   services = {
#     frontend = {
#       cpu           = "256"
#       memory        = "512"
#       desired_count = 1
#       container_definitions = [
#         {
#           name      = "frontend"
#           image     = "702865854817.dkr.ecr.us-east-1.amazonaws.com/madhu-frontend:latest"
#           cpu       = 256
#           memory    = 512
#           portMappings = [{
#             containerPort = 80
#             hostPort      = 80
#             protocol      = "tcp"
#             name          = "frontend-port"
#           }]
#         }
#       ]
#       load_balancer_config = {
#         target_group_arn = module.load_balancer[0].lb_target_group_arns["frontend"]
#         container_name   = "frontend"
#         container_port   = 80
#       }
#       service_connect_configuration = {
#         services = []
#       }
#     }

#     backend = {
#       cpu           = "256"
#       memory        = "512"
#       desired_count = 1
#       container_definitions = [
#         {
#           name      = "backend"
#           image     = "702865854817.dkr.ecr.us-east-1.amazonaws.com/madhu-backend:latest"
#           cpu       = 256
#           memory    = 512
#           portMappings = [{
#             containerPort = 80
#             hostPort      = 8080
#             protocol      = "tcp"
#             name          = "backend-port"
#           }]

#         }
#       ]
#       service_connect_configuration = {
#         services = [
#           {
#             port_name     = "backend-port"
#             discovery_name = "backend"
#             client_alias = {
#               port     = 80
#             }
#           }
#         ]
#       }
#       load_balancer_config = {
#         target_group_arn = module.load_balancer[0].lb_target_group_arns["backend"]
#         container_name   = "backend"
#         container_port   = 80
#       }
#     }
#   }
#   depends_on = [ module.load_balancer ]
# }

# RDS
module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id
  deployment_type = "multi-az-db-cluster"
  subnet_ids = [
    for az, subnet in module.vpc.subnet_ids_by_az : subnet.private
    if subnet.private != null
  ]
  master_password = var.rds_master_password
  tags = {
    Environment = "dev"
    Project     = "modular-infra"
  }
  # engine_version = "14.7"
  instance_class = "db.m5d.large"
  storage_type = "gp3"
  depends_on = [ module.vpc  ]
}


module "security_group" {
  source = "./modules/security_group"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Environment = "dev"
    Project     = "modular-infra"
  }
}

module "ec2" {
  source                      = "./modules/ec2"
  subnet_id                   = values(module.vpc.subnet_ids_by_az)[0].public
  ami_id                      = var.normal_ami
  name                        = "ec2-rds-test"
  associate_public_ip_address = true
  security_group_ids          = [module.security_group.security_group_id]
}
