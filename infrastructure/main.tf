provider "aws" {
  region = var.aws_region
}


# VPC
module "vpc" {
  source = "./modules/VPC"
  name   = var.vpc_name
  vpc_cidr = var.vpc_cidr  # Changed from 'cidr' to 'vpc_cidr'
  azs    = var.availability_zones
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags   = var.tags
  route_entries = var.route_entries
  nat_type = "gateway"
}