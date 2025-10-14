provider "aws" {
  region = var.aws_region
}


# VPC
# module "vpc" {
#   source               = "./modules/vpc"
#   name                 = var.vpc_name
#   vpc_cidr             = var.vpc_cidr
#   azs                  = var.availability_zones
#   public_subnets       = var.public_subnets
#   private_subnets      = var.private_subnets
#   enable_dns_hostnames = true
#   enable_dns_support   = true
#   tags                 = var.tags
#   route_entries        = var.route_entries
#   nat_type             = var.nat_type
#   nat_ami              = var.nat_ami
#   nat_instance_type    = "t2.micro"
# }

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
# module "rds" {
#   source = "./modules/rds"
#   vpc_id = module.vpc.vpc_id
#   deployment_type = "multi-az-db-cluster"
#   subnet_ids = [
#     for az, subnet in module.vpc.subnet_ids_by_az : subnet.private
#     if subnet.private != null
#   ]
#   master_password = var.rds_master_password
#   tags = {
#     Environment = "dev"
#     Project     = "modular-infra"
#   }
#   # instance_class = "db.m5d.large"
#   # storage_type = "gp3"
#   depends_on = [ module.vpc  ]
# }


module "s3" {
  source      = "./modules/s3"
  bucket_name = "madhu-s3-module-test"
  lifecycle_rules = [
    {
      id     = "log"
      filter = { prefix = "log/" }
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]
    }
  ]

  enable_sse_s3           = true
  enable_static_hosting   = true
  index_document          = "main.html"
  error_document          = "error.html"
  force_destroy           = true
  object_lock_enabled     = true
  restrict_public_buckets = false
  block_public_policy = false
  bucket_policy           = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::madhu-s3-module-test/*"
    }
  ]
}
POLICY

}
