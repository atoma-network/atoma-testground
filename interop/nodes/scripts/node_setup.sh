#!/bin/bash
set -e

# Update and install docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-compose git

# Create a directory for Atoma
mkdir -p /opt/atoma
cd /opt/atoma

# Clone your repository with the docker-compose files
# Replace with your actual repository URL
git clone https://github.com/atoma-network/atoma-node.git .

# Create environment file
cat > .env << EOF
POSTGRES_DB=atomadb
POSTGRES_USER=atoma
POSTGRES_PASSWORD=atomapassword
POSTGRES_PORT=5432
ATOMA_SERVICE_PORT=3000
ATOMA_DAEMON_PORT=3001
ATOMA_P2P_PORT=4001
RUST_LOG=info
CHAT_COMPLETIONS_MODEL=mistralai/Mistral-7B-Instruct-v0.2
CHAT_COMPLETIONS_MAX_MODEL_LEN=4096
EOF

# Start the Atoma node with vllm-cpu
docker-compose -f docker-compose.yaml --profile chat_completions_vllm_cpu up -d