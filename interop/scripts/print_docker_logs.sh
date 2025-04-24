#!/bin/bash
set -e

# Check if instance IDs file exists
if [ ! -f "instance_ids.txt" ]; then
  echo "Error: instance_ids.txt file not found. Make sure you've run deploy.sh first."
  exit 1
fi

# Use the KEY_NAME environment variable from the CI environment
if [ -z "$KEY_NAME" ]; then
  echo "Error: KEY_NAME environment variable not set"
  exit 1
fi

echo "Using key file: $KEY_NAME.pem"

# Read instance IDs from file - handle both single and double instance cases
read -r first_id second_id < instance_ids.txt

# Get public IPs
echo "Getting public IPs for instances..."
PROXY_IP=""
NODE_IP=""

# If we have two instance IDs, treat them as node and proxy
if [ -n "$second_id" ]; then
  NODE_IP=$(aws ec2 describe-instances --instance-ids "$first_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
  PROXY_IP=$(aws ec2 describe-instances --instance-ids "$second_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
else
  # If we only have one ID, assume it's the proxy
  PROXY_IP=$(aws ec2 describe-instances --instance-ids "$first_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
fi

# Create a directory for logs
LOG_DIR="docker_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

# Function to collect logs from an instance
collect_logs() {
  local instance_ip=$1
  local instance_name=$2
  local instance_path=$3
  local log_file="$LOG_DIR/${instance_name}_logs.txt"

  echo "Collecting logs from $instance_name ($instance_ip)..."

  # SSH into the instance and collect Docker logs
  if ssh -o StrictHostKeyChecking=no -i "$KEY_NAME.pem" ubuntu@"$instance_ip" "cd $instance_path && sudo docker compose ps && sudo docker compose logs" > "$log_file" 2>&1; then
    echo "Logs from $instance_name saved to $log_file"
    return 0
  else
    echo "Warning: Failed to collect logs from $instance_name"
    return 1
  fi
}

# Collect logs from available instances
failed=0

if [ -n "$NODE_IP" ]; then
  collect_logs "$NODE_IP" "node" "/opt/atoma" || failed=1
fi

if [ -n "$PROXY_IP" ]; then
  collect_logs "$PROXY_IP" "proxy" "/opt/atoma-proxy" || failed=1
fi

# Create a zip file with all logs if any were collected
if [ -d "$LOG_DIR" ] && [ "$(ls -A "$LOG_DIR")" ]; then
  ZIP_FILE="docker_logs_$(date +%Y%m%d_%H%M%S).zip"
  zip -r "$ZIP_FILE" "$LOG_DIR"
  echo "All logs have been collected and saved to $ZIP_FILE"
else
  echo "No logs were collected"
  exit 1
fi

# Exit with failure if any collection failed
[ "$failed" -eq 0 ] || exit 1
