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

# Atoma Proxy Node (Now handles external Sui contract)
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
    "SUI_CONTRACT_ADDRESS=0x...",
    "NODE_MAPPING_CONFIG=/config/node_mapping.yaml"
  ]
}

# Atoma Node Service (Unchanged)
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
    "VLLM_ENDPOINT=http://vllm-service:8000"
  ]
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
