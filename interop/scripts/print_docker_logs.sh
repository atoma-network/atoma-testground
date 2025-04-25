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

# Get the absolute path to the key file
KEY_FILE="$KEY_NAME.pem"

if [ ! -f "$KEY_FILE" ]; then
  echo "Error: Key file not found at $KEY_FILE"
  exit 1
fi

echo "Using key file: $KEY_FILE"

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
  if [ "$instance_name" = "node" ]; then
    # For node, get logs from all relevant services
    if ssh -o StrictHostKeyChecking=no -i "$KEY_FILE" ubuntu@"$instance_ip" "cd $instance_path && \
      echo '=== Docker Compose Status ===' && \
      sudo docker compose ps -a && \
      echo -e '\n=== Atoma Node Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs atoma-node && \
      echo -e '\n=== Postgres Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs postgres-db && \
      echo -e '\n=== Prometheus Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs prometheus && \
      echo -e '\n=== Grafana Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs grafana && \
      echo -e '\n=== Loki Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs loki && \
      echo -e '\n=== Tempo Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs tempo && \
      echo -e '\n=== OTEL Collector Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs otel-collector && \
      echo -e '\n=== VLLM Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs vllm1 vllm2 vllm3 vllm4 vllm5 vllm6 vllm7 vllm8 vllm-cpu vllm-rocm" > "$log_file" 2>&1; then
      echo "Logs from $instance_name saved to $log_file"
      return 0
    else
      echo "Warning: Failed to collect logs from $instance_name"
      return 1
    fi
  elif [ "$instance_name" = "proxy" ]; then
    # For proxy, get logs from all cloud profile services
    if ssh -o StrictHostKeyChecking=no -i "$KEY_FILE" ubuntu@"$instance_ip" "cd $instance_path && \
      echo '=== Docker Compose Status ===' && \
      sudo docker compose ps -a && \
      echo -e '\n=== Proxy Cloud Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs  atoma-proxy-cloud && \
      echo -e '\n=== Database Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs db && \
      echo -e '\n=== Backend Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs backend && \
      echo -e '\n=== Frontend Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs frontend && \
      echo -e '\n=== OTEL Collector Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs otel-collector && \
      echo -e '\n=== Prometheus Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs prometheus && \
      echo -e '\n=== Grafana Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs grafana && \
      echo -e '\n=== Loki Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs loki && \
      echo -e '\n=== Tempo Logs ===' && \
      sudo docker compose -f docker-compose.dev.yaml logs tempo" > "$log_file" 2>&1; then
      echo "Logs from $instance_name saved to $log_file"
      return 0
    else
      echo "Warning: Failed to collect logs from $instance_name"
      return 1
    fi
  else
    echo "Warning: Unknown instance type $instance_name"
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
