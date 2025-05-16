output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "grafana_endpoint" {
  description = "Endpoint for Grafana dashboard"
  value       = module.monitoring.grafana_endpoint
}

output "node_instance_id" {
  description = "ID of the Atoma node instance"
  value       = module.atoma.node_instance_id
}

output "proxy_instance_id" {
  description = "ID of the Atoma proxy instance"
  value       = module.atoma.proxy_instance_id
}

output "node_private_ip" {
  description = "Private IP of the Atoma node instance"
  value       = module.atoma.node_private_ip
}

output "proxy_private_ip" {
  description = "Private IP of the Atoma proxy instance"
  value       = module.atoma.proxy_private_ip
}

output "node_public_ip" {
  description = "Public IP of the Atoma node instance"
  value       = module.atoma.node_public_ip
}

output "proxy_public_ip" {
  description = "Public IP of the Atoma proxy instance"
  value       = module.atoma.proxy_public_ip
}

output "private_key" {
  description = "Private key for SSH access"
  value       = module.atoma.private_key
  sensitive   = true
}
