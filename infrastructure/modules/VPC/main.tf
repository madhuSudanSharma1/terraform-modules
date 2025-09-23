# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support # This option enables DNS resolution within the VPC
  enable_dns_hostnames = var.enable_dns_hostnames 
  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

# Secondary CIDR (optional)
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count      = var.secondary_cidr != null ? 1 : 0
  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidr
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  count = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  map_public_ip_on_launch = true # auto assign public IP to instances launched in this subnet
  availability_zone = element(var.azs, count.index)
  tags = merge(var.tags, { Name = "${var.name}-public-${count.index}" })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone = element(var.azs, count.index)
  tags = merge(var.tags, { Name = "${var.name}-private-${count.index}" })
}

# Route Tables
# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Routes (Public and Private)

# Public routes
resource "aws_route" "public_routes" {
  for_each             = { for idx, rt in var.route_entries.public : idx => rt }
  route_table_id       = aws_route_table.public.id
  destination_cidr_block = each.value.cidr
  gateway_id           = aws_internet_gateway.this[0].id
}

# Private routes
resource "aws_route" "private_routes" {
  for_each             = { for idx, rt in var.route_entries.private : idx => rt }
  route_table_id       = aws_route_table.private.id
  destination_cidr_block = each.value.cidr
  nat_gateway_id       = var.nat_type == "gateway" ? try(aws_nat_gateway.this[0].id, null) : null
  # instance_id          = var.nat_type == "instance" ? try(aws_instance.nat_instance[0].id, null) : null
}



# NAT (Gateway or Instance)
# EIP for NAT Gateway
resource "aws_eip" "nat" {
  count = var.nat_type == "gateway" && length(var.public_subnets) > 0 ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_type == "gateway" && length(var.public_subnets) > 0 ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = element(aws_subnet.public[*].id, 0)
  tags          = merge(var.tags, { Name = "${var.name}-natgw" })
}

# NAT Instance (if chosen instead of gateway)
resource "aws_instance" "nat_instance" {
  count                       = var.nat_type == "instance" ? 1 : 0
  ami                         = var.nat_ami
  instance_type               = var.nat_instance_type
  subnet_id                   = element(aws_subnet.public[*].id, 0)
  associate_public_ip_address = true
  source_dest_check           = false
  tags                        = merge(var.tags, { Name = "${var.name}-nat-instance" })
}