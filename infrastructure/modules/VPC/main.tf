# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support # This option enables DNS resolution within the VPC
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = merge(var.tags, { Name = "${var.name}-vpc" })
}

# Secondary CIDR (optional)
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count      = var.secondary_cidr != null ? 1 : 0
  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidr
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true # auto assign public IP to instances launched in this subnet
  availability_zone       = var.azs[count.index % length(var.azs)]
  tags                    = merge(var.tags, { Name = "${var.name}-public-${count.index}" })
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = var.azs[count.index % length(var.azs)]
  tags                    = merge(var.tags, { Name = "${var.name}-private-${count.index}" })
}

# Route Tables - One per AZ
# Public route tables
resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? length(var.azs) : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt-${var.azs[count.index]}" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index % length(var.azs)].id
}

# Private route tables
resource "aws_route_table" "private" {
  count  = length(var.private_subnets) > 0 ? length(var.azs) : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt-${var.azs[count.index]}" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % length(var.azs)].id
}

# Routes (Public and Private)

# Public routes - for each public route table
resource "aws_route" "public_routes" {
  for_each = {
    for route_combo in flatten([
      for rt_idx, rt in var.route_entries.public : [
        for az_idx in range(length(var.azs)) : {
          key                    = "${rt_idx}-${az_idx}"
          route_table_id         = aws_route_table.public[az_idx].id
          destination_cidr_block = rt.cidr
        }
      ]
    ]) : route_combo.key => route_combo
  }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = aws_internet_gateway.this[0].id
}

# Private routes - for each private route table
resource "aws_route" "private_routes_instance_gateway" {
  for_each = var.nat_type == "gateway" ? {
    for route_combo in flatten([
      for rt_idx, rt in var.route_entries.private : [
        for az_idx in range(length(var.azs)) : {
          key                    = "${rt_idx}-${az_idx}"
          route_table_id         = aws_route_table.private[az_idx].id
          destination_cidr_block = rt.cidr
          nat_gateway_id         = aws_nat_gateway.this[az_idx].id
        }
      ]
    ]) : route_combo.key => route_combo
  } : {}

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  nat_gateway_id         = each.value.nat_gateway_id
}

resource "aws_route" "private_routes_instance_instance" {
  for_each = var.nat_type == "instance" ? {
    for route_combo in flatten([
      for rt_idx, rt in var.route_entries.private : [
        for az_idx in range(length(var.azs)) : {
          key                    = "${rt_idx}-${az_idx}"
          route_table_id         = aws_route_table.private[az_idx].id
          destination_cidr_block = rt.cidr
          network_interface_id   = module.nat_instance[az_idx].primary_network_interface_id
        }
      ]
    ]) : route_combo.key => route_combo
  } : {}

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  network_interface_id   = each.value.network_interface_id
}

# NAT (Gateway or Instance) - One per AZ
# EIP for NAT Gateway - One per AZ
resource "aws_eip" "nat" {
  count  = var.nat_type == "gateway" && length(var.public_subnets) > 0 ? length(var.azs) : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-eip-${var.azs[count.index]}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_type == "gateway" && length(var.public_subnets) > 0 ? length(var.azs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index * (length(var.public_subnets) / length(var.azs))].id
  tags          = merge(var.tags, { Name = "${var.name}-natgw-${var.azs[count.index]}" })
}

# NAT Role
module "nat_iam_role" {
  count  = var.nat_type == "instance" ? 1 : 0
  source = "../IAM_Roles"

  role_name               = "${var.name}-nat-role"
  assume_role_policy      = data.aws_iam_policy_document.nat_assume_role.json
  policy_arns             = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  inline_policy           = ""
  create_instance_profile = true
  tags                    = var.tags
}

# NAT SG
module "nat_sg" {
  count  = var.nat_type == "instance" ? 1 : 0
  source = "../security-group"

  security_group_name        = "${var.name}-nat-sg"
  security_group_description = "Security group for NAT instances"
  vpc_id                     = aws_vpc.this.id

  ingress_rules = [
    {
      description = "Allow inbound SSH"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow inbound HTTP"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["10.0.0.0/16"]
    }
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


data "aws_iam_policy_document" "nat_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# NAT Instance (if chosen instead of gateway) - One per AZ
module "nat_instance" {
  count  = var.nat_type == "instance" ? length(var.azs) : 0
  source = "../EC2"

  ami_id                      = var.nat_ami
  instance_type               = var.nat_instance_type
  subnet_id                   = aws_subnet.public[count.index * (length(var.public_subnets) / length(var.azs))].id
  associate_public_ip_address = true
  source_dest_check           = false

  iam_instance_profile = module.nat_iam_role[0].instance_profile_name
  security_group_ids   = [module.nat_sg[0].security_group_id]

  user_data = ""

  tags = merge(var.tags, { Name = "${var.name}-nat-instance-${var.azs[count.index]}" })
  name = "${var.name}-nat-instance-${var.azs[count.index]}"
}