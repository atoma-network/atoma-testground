# VPC and networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

# Security group allowing container communication
resource "aws_security_group" "container_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }
}

# ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "dev-cluster"
}

# Task definitions for your containers
resource "aws_ecs_task_definition" "container1" {
  family                   = "container1"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name  = "container1"
    image = "atoma-node:latest"
  }])
}

resource "aws_ecs_task_definition" "container2" {
  family                   = "container2"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name  = "container2"
    image = "atoma-proxy:latest"
  }])
}
