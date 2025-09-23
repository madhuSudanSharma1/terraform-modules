aws_region         = "us-east-1"
vpc_name           = "madhu-vpc"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b","us-east-1c","us-east-1d"]
public_subnets     = ["10.0.1.0/24", "10.0.3.0/24","10.0.5.0/24","10.0.7.0/24"]
private_subnets    = ["10.0.2.0/24", "10.0.4.0/24","10.0.6.0/24","10.0.8.0/24"]
secondary_cidr    = null
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
    { cidr = "0.0.0.0/0", use_nat_gateway = true, use_nat_instance = false }
  ]
}
