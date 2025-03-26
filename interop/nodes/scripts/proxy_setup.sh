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
mkdir -p /opt/atoma-proxy
cd /opt/atoma-proxy

# Clone your repository with the docker-compose files
# Replace with your actual repository URL
git clone https://github.com/atoma-network/atoma-proxy.git .

# Create environment file
cat > .env << EOF
POSTGRES_DB=atomadb
POSTGRES_USER=atoma
POSTGRES_PASSWORD=atomapassword
POSTGRES_PORT=5432
ATOMA_SERVICE_PORT=8080
ATOMA_PROXY_SERVICE_PORT=8081
ATOMA_P2P_SERVICE_PORT=8083
RUST_LOG=info
EOF

# Create a simple config.toml file (update with your actual config)
cat > config.toml << EOF
[atoma_service]
bind_addr = "0.0.0.0:8080"

[atoma_proxy_service]
bind_addr = "0.0.0.0:8081"

[p2p]
external_addr = "/ip4/0.0.0.0/tcp/8083"
listen_addr = "/ip4/0.0.0.0/tcp/8083"
EOF

# Start the Atoma proxy with local profile
docker-compose -f docker-compose.yaml --profile local up -d