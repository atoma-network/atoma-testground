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

# Optional variables with defaults
variable "data_root_path" {
  description = "Root path for persistent data storage"
  type        = string
  default     = "/var/lib"
}

variable "proxy_port" {
  description = "External port for the Atoma proxy"
  type        = number
  default     = 8000
}

variable "node_port" {
  description = "External port for the Atoma node"
  type        = number
  default     = 5000
}

variable "vllm_port" {
  description = "External port for the vLLM service"
  type        = number
  default     = 8000
}
