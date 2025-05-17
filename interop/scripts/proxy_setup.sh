#!/bin/bash
set -e

# Update system and install basic requirements
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-compose git

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl"
chmod +x kubectl

# Make it executable and move it to the right location
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify the installation
kubectl version --client

# Install k3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -

# Wait for k3s to be ready
sleep 30

# Configure kubectl to use k3s
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Helm repositories
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install cert-manager
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.3 \
  --set installCRDs=true

# Install nginx-ingress-controller
kubectl create namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer

# Wait for all pods to be ready
echo "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all -A --timeout=300s
# Print cluster information
echo "Kubernetes cluster is ready!"
kubectl get nodes
kubectl get pods -A

# Create a directory for Atoma
mkdir -p /opt/atoma-proxy
cd /opt/atoma-proxy

# Clone your repository with the docker-compose files
# Use the branch specified in the environment variable, defaulting to main if not set
BRANCH=mc/kubernetes-setup
git clone -b $BRANCH https://github.com/atoma-network/atoma-proxy.git .

# Deploy the Atoma proxy using Helm
echo "Deploying Atoma proxy using Helm..."
cd helm/atoma-proxy
./scripts/deploy.sh -e dev -p password

# Wait for the deployment to be ready
echo "Waiting for Atoma proxy deployment to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=atoma-proxy -n atoma-proxy-dev --timeout=300s

# Verify the installation
echo "Verifying Atoma proxy installation..."

echo -e "\n=== Checking Pods ==="
kubectl get pods -n atoma-proxy
echo -e "\nPod Details:"
kubectl describe pods -n atoma-proxy

echo -e "\n=== Checking Ingress Resources ==="
kubectl get ingress -n atoma-proxy
echo -e "\nIngress Details:"
kubectl describe ingress -n atoma-proxy

echo -e "\n=== Checking Services ==="
kubectl get svc -n atoma-proxy
echo -e "\nService Details:"
kubectl describe svc -n atoma-proxy

# Verify all pods are running
echo -e "\n=== Verifying Pod Status ==="
if kubectl get pods -n atoma-proxy | grep -q "Running"; then
    echo "✓ All pods are running"
else
    echo "✗ Some pods are not running. Please check the pod status above."
    exit 1
fi
chmod +x scripts/deploy.sh

# Verify ingress is configured
echo -e "\n=== Verifying Ingress Configuration ==="
if kubectl get ingress -n atoma-proxy | grep -q "atoma-proxy"; then
    echo "✓ Ingress is configured"
else
    echo "✗ Ingress is not configured. Please check the ingress status above."
    exit 1
fi

# Verify services are running
echo -e "\n=== Verifying Services ==="
if kubectl get svc -n atoma-proxy | grep -q "atoma-proxy"; then
    echo "✓ Services are running"
else
    echo "✗ Services are not running. Please check the service status above."
    exit 1
fi

echo -e "\n=== Installation Verification Complete ==="
echo "If you see any issues above, please check the detailed output for troubleshooting."