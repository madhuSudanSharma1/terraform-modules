variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"  
}
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "my-vpc"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}
variable "secondary_cidr" {
  description = "Secondary CIDR block for the VPC (optional)"
  type        = string
  default     = null
}
variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "modular-infra"
  }
}
variable "nat_type" {
  description = "Type of NAT (gateway or instance)"
  type        = string
  default     = "gateway"
}
variable "route_entries" {
  description = "Routes grouped by route table type"
  type = object({
    public  = optional(list(object({
      cidr             = string
      gateway_id       = optional(string)
      use_nat_gateway  = optional(bool, false)
      use_nat_instance = optional(bool, false)
    })), [])
    private = optional(list(object({
      cidr             = string
      gateway_id       = optional(string)
      use_nat_gateway  = optional(bool, false)
      use_nat_instance = optional(bool, false)
    })), [])
  })
  default = {
    public  = [{ cidr = "0.0.0.0/0" }]
    private = [{ cidr = "0.0.0.0/0", use_nat_gateway = true }]
  }
}