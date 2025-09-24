output "instance_id" {
  description = "The ID of the instance"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "primary_network_interface_id" {
  description = "The primary network interface ID"
  value       = aws_instance.this.primary_network_interface_id
}
