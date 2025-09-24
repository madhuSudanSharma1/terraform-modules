output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "subnet_ids_by_az" {
  description = "Public and Private subnet IDs keyed by availability zone"
  value = {
    for i, az in var.azs :
    az => {
      public  = try(aws_subnet.public[i].id, null)
      private = try(aws_subnet.private[i].id, null)
    }
  }
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = var.nat_type == "gateway" ? [for ngw in aws_nat_gateway.this : ngw.id] : []
}


output "nat_instance_ids" {
  description = "List of NAT Instance IDs"
  value       = var.nat_type == "instance" ? [for ni in module.nat_instance : ni.instance_id] : []
}

output "public_route_table_ids" {
  description = "List of Public Route Table IDs"
  value       = [for rt in aws_route_table.public : rt.id]
}

output "private_route_table_ids" {
  description = "List of Private Route Table IDs"
  value       = [for rt in aws_route_table.private : rt.id]
}

output "iam_instance_profile" {
  description = "IAM Instance Profile for NAT instances"
  value       = var.nat_type == "instance" ? module.nat_iam_role[0].instance_profile_name : null
}