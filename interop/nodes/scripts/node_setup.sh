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

# Generate configuration files
echo "Generating configuration files..."
chmod +x ./atoma-node/generate-config.sh
./atoma-node/generate-config.sh

# Copy configuration files to the right location
echo "Setting up configuration..."
cp config.toml .env ./


# Start the Atoma node with vllm-cpu
docker-compose -f docker-compose.yaml --profile chat_completions_vllm_cpu up -d