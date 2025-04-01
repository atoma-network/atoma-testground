#!/bin/bash
set -e

# Add debugging
echo "Listing contents of script directory..."
ls -la /var/lib/cloud/instance/scripts/

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
git clone https://github.com/atoma-network/atoma-node.git .

# Add more debugging
echo "Attempting to copy config files..."
ls -la /var/lib/cloud/instance/scripts/.env || echo ".env not found"
ls -la /var/lib/cloud/instance/scripts/config.toml || echo "config.toml not found"

# Copy the pre-made configuration files
cp /var/lib/cloud/instance/scripts/.env . || echo "Failed to copy .env"
cp /var/lib/cloud/instance/scripts/config.toml . || echo "Failed to copy config.toml"

# Verify the copies
echo "Checking if files were copied..."
ls -la .env || echo ".env not present in destination"
ls -la config.toml || echo "config.toml not present in destination"

# Start the Atoma node with vllm-cpu
COMPOSE_PROFILES=mistralrs-cpu,non-confidential docker compose up -d