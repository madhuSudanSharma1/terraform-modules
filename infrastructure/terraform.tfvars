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
nat_type = "instance"
route_entries = {
  public = [
    { cidr = "0.0.0.0/0" }
  ]
  private = [
    { cidr = "0.0.0.0/0", use_nat_gateway = false, use_nat_instance = true }
  ]
}
nat_ami = "ami-024cf76afbc833688"
normal_ami = "ami-08982f1c5bf93d976"