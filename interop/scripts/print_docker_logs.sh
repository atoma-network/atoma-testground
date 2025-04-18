#!/bin/bash
set -e

# Check if instance IDs file exists
if [ ! -f "instance_ids.txt" ]; then
  echo "Error: instance_ids.txt file not found. Make sure you've run deploy.sh first."
  exit 1
fi

# Read instance IDs from file
read NODE_INSTANCE_ID PROXY_INSTANCE_ID < instance_ids.txt

# Get public IPs
echo "Getting public IPs for instances..."
NODE_IP=$(aws ec2 describe-instances --instance-ids $NODE_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
PROXY_IP=$(aws ec2 describe-instances --instance-ids $PROXY_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo "Node IP: $NODE_IP"
echo "Proxy IP: $PROXY_IP"

# Create a directory for logs
LOG_DIR="docker_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p $LOG_DIR

# Function to collect logs from an instance
collect_logs() {
  local instance_ip=$1
  local instance_name=$2
  local log_file="$LOG_DIR/${instance_name}_logs.txt"

  echo "Collecting logs from $instance_name ($instance_ip)..."

  # SSH into the instance and collect Docker logs
  ssh -o StrictHostKeyChecking=no -i atoma-key.pem ubuntu@$instance_ip "cd /opt/atoma && sudo docker compose logs" > "$log_file" 2>&1

  echo "Logs from $instance_name saved to $log_file"
}

# Collect logs from both instances
collect_logs $NODE_IP "node"
collect_logs $PROXY_IP "proxy"

# Create a zip file with all logs
ZIP_FILE="docker_logs_$(date +%Y%m%d_%H%M%S).zip"
zip -r $ZIP_FILE $LOG_DIR

echo "All logs have been collected and saved to $ZIP_FILE"
echo "You can download this file to your local machine for analysis."
