variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where instances will be launched"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "atoma-key"
}

variable "ami_id" {
  description = "AMI ID for the instances"
  type        = string
  default     = "ami-03f8acd418785369b" # Ubuntu 22.04 LTS
}

variable "node_instance_type" {
  description = "Instance type for the Atoma node"
  type        = string
  default     = "g4dn.2xlarge" # GPU instance with NVIDIA T4 GPU
}

variable "proxy_instance_type" {
  description = "Instance type for the Atoma proxy"
  type        = string
  default     = "c5.2xlarge" # Sufficient for proxy
}

variable "deploy_node" {
  description = "Whether to deploy the Atoma node instance"
  type        = bool
  default     = true
}

variable "deploy_proxy" {
  description = "Whether to deploy the Atoma proxy instance"
  type        = bool
  default     = true
}

variable "node_branch" {
  description = "Git branch to use for the Atoma node repository"
  type        = string
  default     = "main"
}

variable "proxy_branch" {
  description = "Git branch to use for the Atoma proxy repository"
  type        = string
  default     = "main"
}
