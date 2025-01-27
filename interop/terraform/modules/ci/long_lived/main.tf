# main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_network" "atoma_net" {
  name = "atoma-network"
}

# Add variables for configuration
variable "hf_token" {
  description = "HuggingFace token for model access"
  type        = string
  sensitive   = true
}

variable "sui_contract_address" {
  description = "Sui contract address for Atoma Network"
  type        = string
}

variable "atoma_node_badge_id" {
  description = "Node badge ID from the Sui contract"
  type        = string
}

# Modified Atoma Proxy configuration
resource "docker_container" "atoma_proxy" {
  name  = "atoma-proxy"
  image = "your-proxy-image:latest"

  ports {
    internal = 8000
    external = 8000
  }

  networks_advanced {
    name = docker_network.atoma_net.name
  }

  env = [
    "SUI_RPC_ENDPOINT=https://fullnode.testnet.sui.io:443",
    "SUI_CONTRACT_ADDRESS=${var.sui_contract_address}",
    "NODE_MAPPING_CONFIG=/config/node_mapping.yaml",
    "ATOMA_NODE_BADGE_ID=${var.atoma_node_badge_id}"
  ]

  # Add volume for persistent storage of stack data
  volumes {
    container_path = "/data"
    host_path      = "/var/lib/atoma-proxy/data"
  }
}

# Modified Atoma Node configuration
resource "docker_container" "atoma_node" {
  name  = "atoma-node"
  image = "your-atoma-node-image:latest"

  ports {
    internal = 5000
    external = 5000
  }

  networks_advanced {
    name = docker_network.atoma_net.name
  }

  env = [
    "HF_TOKEN=${var.hf_token}",
    "VLLM_ENDPOINT=http://vllm-service:8000",
    "ATOMA_NODE_BADGE_ID=${var.atoma_node_badge_id}",
    "SUI_CONTRACT_ADDRESS=${var.sui_contract_address}"
  ]

  # Add volumes for model caching and persistent storage
  volumes {
    container_path = "/app/data"
    host_path      = "/var/lib/atoma-node/data"
  }

  volumes {
    container_path = "/app/model-cache"
    host_path      = "/var/lib/atoma-node/model-cache"
  }
}

# vLLM Service (Simplified for Dev)
resource "docker_container" "vllm_service" {
  name  = "vllm-service"
  image = "vllm/vllm-openai:latest"
  gpu   = true # Requires NVIDIA Container Toolkit
  ports {
    internal = 8000
    external = 8000
  }
  networks_advanced {
    name = docker_network.atoma_net.name
  }
  command = [
    "--model", "mistralai/Mistral-7B-Instruct-v0.1",
    "--dtype", "float16",
    "--api-key", "dummy-key"
  ]
}
