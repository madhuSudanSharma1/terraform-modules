provider "aws" {
  region = var.aws_region
}


# VPC
module "vpc" {
  source               = "./modules/VPC"
  name                 = var.vpc_name
  vpc_cidr             = var.vpc_cidr # Changed from 'cidr' to 'vpc_cidr'
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

module "public_sg" {
  source = "./modules/security-group"

  security_group_name        = "${var.vpc_name}-public-sg"
  security_group_description = "Security group for public instances"
  vpc_id                     = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "Allow inbound SSH"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = var.tags
}

# Bastion Host
module "ec2_instance" {
  source          = "./modules/EC2"
  name           = "Bastion-Host"
  instance_type   = "t2.micro"
  ami_id          = var.normal_ami
  subnet_id       = module.vpc.subnet_ids_by_az[var.availability_zones[0]].public
  key_name        = "test-key-pair"
  security_group_ids = [module.public_sg.security_group_id] 
  associate_public_ip_address = true
  tags = merge(var.tags, { Name = "Bastion-Host" })
  iam_instance_profile = module.vpc.iam_instance_profile
}

#Private Instance
module "private_ec2_instance" {
  source          = "./modules/EC2"
  name           = "Private-Instance"
  instance_type   = "t2.micro"
  ami_id          = var.normal_ami
  subnet_id       = module.vpc.subnet_ids_by_az[var.availability_zones[0]].private
  security_group_ids = [module.public_sg.security_group_id]
  key_name        = "test-key-pair"
  associate_public_ip_address = false
  tags = merge(var.tags, { Name = "Private-Instance" })
  iam_instance_profile = module.vpc.iam_instance_profile
}
