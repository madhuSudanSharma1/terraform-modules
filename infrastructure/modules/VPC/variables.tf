variable "name" {
  description = "Prefix name for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC"
  type        = string
}

variable "secondary_cidr" {
  description = "Optional secondary CIDR block"
  type        = string
  default     = null
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = []
}

variable "nat_type" {
  description = "Type of NAT (gateway or instance)"
  type        = string
  default     = "gateway"
}

variable "nat_ami" {
  description = "AMI ID for NAT instance (if using instance)"
  type        = string
  default     = ""
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance"
  type        = string
  default     = "t3.micro"
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
    public  = []
    private = []
  }
}


variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}
