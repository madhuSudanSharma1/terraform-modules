output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "subnet_ids_by_az" {
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
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = try(aws_nat_gateway.this[0].id, null)
}

output "nat_instance_id" {
  value = try(aws_instance.nat_instance[0].id, null)
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}
