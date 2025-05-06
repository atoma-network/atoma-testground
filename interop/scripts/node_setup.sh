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


# Install NVIDIA driver and CUDA
apt-get update
apt-get install -y linux-headers-$(uname -r)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

apt-get update
apt-get install -y nvidia-driver-525 nvidia-docker2 nvidia-container-runtime
apt-get install -y python3-pip
pip install --upgrade pynvml
systemctl restart docker

# Create a directory for Atoma
mkdir -p /opt/atoma
cd /opt/atoma

# Clone your repository with the docker-compose files
# Use the branch specified in the environment variable, defaulting to main if not set
# BRANCH=${NODE_BRANCH:-main}
BRANCH=mc/feat/integrate-sglang
git clone -b $BRANCH https://github.com/atoma-network/atoma-node.git .

