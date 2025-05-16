output "node_instance_id" {
  description = "ID of the Atoma node instance"
  value       = try(aws_instance.atoma_node[0].id, null)
}

output "proxy_instance_id" {
  description = "ID of the Atoma proxy instance"
  value       = try(aws_instance.atoma_proxy[0].id, null)
}

output "node_private_ip" {
  description = "Private IP of the Atoma node instance"
  value       = try(aws_instance.atoma_node[0].private_ip, null)
}

output "proxy_private_ip" {
  description = "Private IP of the Atoma proxy instance"
  value       = try(aws_instance.atoma_proxy[0].private_ip, null)
}

output "node_public_ip" {
  description = "Public IP of the Atoma node instance"
  value       = try(aws_instance.atoma_node[0].public_ip, null)
}

output "proxy_public_ip" {
  description = "Public IP of the Atoma proxy instance"
  value       = try(aws_instance.atoma_proxy[0].public_ip, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.atoma.id
}
