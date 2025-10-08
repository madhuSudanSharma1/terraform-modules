provider "aws" {
  region = var.aws_region
}


# VPC
module "vpc" {
  source               = "./modules/VPC"
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

module "ecs" {
  source               = "./modules/ECS"
  cluster_name         = "madhu-ecs-cluster"
  launch_type          = "FARGATE"
  subnets              = module.vpc.subnet_ids_by_az
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr_block
  load_balancer_config = var.lb_config
  services = {
    frontend = {
      task_family   = "frontend"
      cpu           = "256"
      memory        = "512"
      desired_count = 1
      container_definitions = [
        {
          name      = "frontend"
          image     = "702865854817.dkr.ecr.us-east-1.amazonaws.com/madhu-frontend:latest"
          cpu       = 256
          memory    = 512
          essential = true
          portMappings = [{
            containerPort = 80
            hostPort      = 80
            protocol      = "tcp"
            name          = "frontend-port"
          }]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/ecs/madhu-ecs-cluster/frontend"
              awslogs-region        = var.aws_region
              awslogs-stream-prefix = "ecs"
            }
          }
        }
      ]
      load_balancer_config = {
        target_group_arn = module.ecs.lb_target_group_arns["frontend"]
        container_name   = "frontend"
        container_port   = 80
      }
      service_connect_configuration = {
        services = []
      }
    }

    backend = {
      task_family   = "backend"
      cpu           = "256"
      memory        = "512"
      desired_count = 1
      container_definitions = [
        {
          name      = "backend"
          image     = "702865854817.dkr.ecr.us-east-1.amazonaws.com/madhu-backend:latest"
          cpu       = 256
          memory    = 512
          essential = true
          portMappings = [{
            containerPort = 80
            hostPort      = 80
            protocol      = "tcp"
            name          = "backend-port"
          }]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/ecs/madhu-ecs-cluster/backend"
              awslogs-region        = var.aws_region
              awslogs-stream-prefix = "ecs"
            }
          }
        }
      ]
      service_connect_configuration = {
        services = [
          {
            port_name = "backend-port"
            discovery_name = "backend"
            client_alias = {
              port     = 80
            }
          }
        ]
      }
    }
  }
}


