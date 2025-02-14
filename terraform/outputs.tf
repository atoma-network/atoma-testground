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
