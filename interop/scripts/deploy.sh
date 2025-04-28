#!/bin/bash
set -e

# Variables
REGION="us-west-2"
NODE_INSTANCE_TYPE="g4dn.2xlarge"  # GPU instance with NVIDIA T4 GPU for ML workloads
# NODE_INSTANCE_TYPE="c5.2xlarge"  # CPU instance
PROXY_INSTANCE_TYPE="c5.2xlarge"  # Sufficient for proxy
AMI_ID="ami-03f8acd418785369b"  # Ubuntu 22.04 LTS
KEY_NAME="${KEY_NAME:-atoma-key}"  # Use the environment variable if set, or default to "atoma-key"
SECURITY_GROUP_NAME="atoma-sg"
VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text)

# Get the first subnet in the VPC
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[0].SubnetId" \
  --output text)

# Create key pair if it doesn't exist
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME > /dev/null 2>&1; then
  echo "Creating key pair $KEY_NAME..."
  aws ec2 create-key-pair --no-cli-pager --key-name $KEY_NAME --query "KeyMaterial" --output text > $KEY_NAME.pem
  chmod 400 $KEY_NAME.pem
fi

# Get or create security group
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "")

if [ -z "$SECURITY_GROUP_ID" ]; then
  echo "Creating security group $SECURITY_GROUP_NAME..."
  SECURITY_GROUP_ID=$(aws ec2 create-security-group --no-cli-pager --group-name $SECURITY_GROUP_NAME --description "Security group for Atoma" --vpc-id $VPC_ID --output text --query "GroupId")

  # Allow SSH
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

  # Allow inbound traffic for Docker ports
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 3001 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 4001 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol udp --port 4001 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 8080-8083 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol udp --port 8080-8083 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 8000 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

  # Allow outbound traffic for Docker ports
  aws ec2 authorize-security-group-egress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 4001 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-egress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol udp --port 4001 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-egress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 8080-8083 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-egress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol udp --port 8080-8083 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-egress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 8000 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-egress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

  # Allow HTTP traffic for monitoring services
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 9090 --cidr 0.0.0.0/0  # Prometheus
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 30000 --cidr 0.0.0.0/0  # Grafana

  # Allow all traffic between instances in the security group
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol all --source-group $SECURITY_GROUP_ID
fi

# Launch Atoma Node instance
echo "Launching Atoma Node instance..."
NODE_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $NODE_INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --user-data file://node_setup.sh \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3"}}]' \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=atoma-node}]" \
  --query "Instances[0].InstanceId" \
  --output text)

# Launch Atoma Proxy instance
echo "Launching Atoma Proxy instance..."
PROXY_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $PROXY_INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --user-data file://proxy_setup.sh \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3"}}]' \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=atoma-proxy}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids $NODE_INSTANCE_ID $PROXY_INSTANCE_ID

# Save instance IDs for cleanup
echo "$NODE_INSTANCE_ID $PROXY_INSTANCE_ID" > instance_ids.txt

# Get public IPs
NODE_IP=$(aws ec2 describe-instances --instance-ids $NODE_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
PROXY_IP=$(aws ec2 describe-instances --instance-ids $PROXY_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo "Atoma Node IP: $NODE_IP"
echo "Atoma Proxy IP: $PROXY_IP"

# Update config.toml with PROXY_IP in bootstrap_node_addrs
echo "Updating config.toml with PROXY_IP in bootstrap_node_addrs: $PROXY_IP"
# Create a temporary file with the updated content
awk -v proxy_ip="$PROXY_IP" '
  /bootstrap_node_addrs/ {
    print "bootstrap_node_addrs = [ \"/ip4/" proxy_ip "/tcp/4001\", \"/ip4/" proxy_ip "/udp/4001/quic-v1\" ]"
    next
  }
  { print }
' config.toml > config.toml.tmp
# Atomically replace the original file
mv config.toml.tmp config.toml
echo "Updated config.toml with PROXY_IP in bootstrap_node_addrs: $PROXY_IP"

# Output information for GitHub actions
echo "NODE_IP=$NODE_IP" >> $GITHUB_ENV
echo "PROXY_IP=$PROXY_IP" >> $GITHUB_ENV
echo "NODE_INSTANCE_ID=$NODE_INSTANCE_ID" >> $GITHUB_ENV
echo "PROXY_INSTANCE_ID=$PROXY_INSTANCE_ID" >> $GITHUB_ENV

# Wait a bit for the instances to be ready for SSH
echo "Waiting for SSH to be available..."
sleep 30

# Copy configuration files to the node instance
echo "Copying configuration files to node instance..."
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem .env ubuntu@$NODE_IP:/home/ubuntu/
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem config.toml ubuntu@$NODE_IP:/home/ubuntu/

# Copy the node local key to the node instance
echo "Copying node local key to node instance..."
# Create data directory if it doesn't exist
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$NODE_IP 'mkdir -p /home/ubuntu/data'
# Copy the node local key to the node instance
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem data/node_local_key ubuntu@$NODE_IP:/home/ubuntu/data/local_key

# Copy the proxy local key to the proxy instance
echo "Copying proxy local key to proxy instance..."
# Create data directory if it doesn't exist
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP 'mkdir -p /home/ubuntu/data'
# Copy the proxy local key to the proxy instance
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem data/proxy_local_key ubuntu@$PROXY_IP:/home/ubuntu/data/local_key


# Copy the sui config to the node instance
echo "Copying sui config to node instance..."
# Create .sui directory if it doesn't exist
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$NODE_IP 'mkdir -p ~/.sui'
# Copy sui.toml to the correct location
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem -r sui_config/ ubuntu@$NODE_IP:~/.sui/

# Copy the init.sql to the proxy instance
echo "Copying database initialization script..."
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem init.sql ubuntu@$PROXY_IP:/home/ubuntu/

# Copy the sui config to the proxy instance
echo "Copying sui config to proxy instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP 'sudo mkdir -p /root/.sui'
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem -r sui_config/ ubuntu@$PROXY_IP:/tmp/sui_config
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP 'sudo cp -r /tmp/sui_config /root/.sui/ && sudo chown -R root:root /root/.sui'

# Copy the proxy environment variables and config to the proxy instance
echo "Copying proxy environment variables and config to proxy instance..."
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem .proxy.env ubuntu@$PROXY_IP:/home/ubuntu/.env
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem config.proxy.toml ubuntu@$PROXY_IP:/home/ubuntu/config.toml

sleep 500

# Copy the init.sql to the proxy instance
echo "Copying init.sql to proxy instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP 'sudo mv /home/ubuntu/init.sql /opt/atoma-proxy/'

# Move files to the correct location using SSH
echo "Moving environment variables and config to the Node instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$NODE_IP 'sudo mv /home/ubuntu/.env /opt/atoma/ && sudo mv /home/ubuntu/config.toml /opt/atoma/'

echo "Moving environment variables and config to the Proxy instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP 'sudo mv /home/ubuntu/.env /opt/atoma-proxy/ && sudo mv /home/ubuntu/config.toml /opt/atoma-proxy/'

# Copy the local key to the correct location on proxy
echo "Copying local key to proxy instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP 'sudo mkdir -p /opt/atoma-proxy/data && sudo mv /home/ubuntu/data/* /opt/atoma-proxy/data/ && sudo chown -R root:root /opt/atoma-proxy/data'

# Copy the local key to the correct location on node
echo "Copying local key to node instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$NODE_IP 'sudo mkdir -p /opt/atoma/data && sudo mv /home/ubuntu/data/* /opt/atoma/data/ && sudo chown -R root:root /opt/atoma/data'

# Start the Atoma proxy with local profiles
echo "Starting Atoma proxy..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP 'cd /opt/atoma-proxy && export PLATFORM=linux/amd64 && export SUI_CONFIG_PATH=/root/.sui/sui_config && sudo docker compose -f docker-compose.dev.yaml --profile cloud up -d --build'

# Start the Atoma node with mistralrs-cpu and log the output
echo "Starting Docker Compose..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$NODE_IP 'cd /opt/atoma && export PLATFORM=linux/amd64  && sudo -E COMPOSE_PROFILES=gpu,chat_completions_vllm docker compose -f docker-compose.dev.yaml up -d'

# Wait for proxy service to be up and migrations to be complete
echo "Waiting for proxy service and migrations..."
max_attempts=60  # Increased max attempts to give more time
for i in {1..60}; do
  # First check if proxy container is running
  proxy_status=$(ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP "cd /opt/atoma-proxy && sudo docker compose ps atoma-proxy-cloud --format json" 2>/dev/null)
  echo "Proxy status: $proxy_status"

  # Then check if database has the required tables
  if echo "$proxy_status" | grep -q "running" && \
     ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP "cd /opt/atoma-proxy && sudo docker exec atoma-proxy-db-1 psql -U atoma -d atoma -c '\d nodes' > /dev/null 2>&1"; then
    echo "✓ Proxy service is running and migrations are complete"
    break
  fi

  if [ $i -eq $max_attempts ]; then
    echo "WARNING: Maximum wait time reached. Proceeding anyway..."
  fi

  echo "Waiting for proxy service and migrations... attempt $i/$max_attempts"
  sleep 30
done

# Verify the state before proceeding
if ! ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP "cd /opt/atoma-proxy && sudo docker exec atoma-proxy-db-1 psql -U atoma -d atoma -c '\d nodes'" > /dev/null 2>&1; then
  echo "ERROR: Database migrations did not complete successfully"
  exit 1
fi

# First, create the functions
echo "Creating database functions..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP "cd /opt/atoma-proxy && sudo docker exec -i atoma-proxy-db-1 psql -U atoma -d atoma < /opt/atoma-proxy/init.sql"

# Then, call the initialization function with the parameters
echo "Initializing database with node IP and API token..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$PROXY_IP "cd /opt/atoma-proxy && sudo docker exec atoma-proxy-db-1 psql -U atoma -d atoma -c \"SELECT initialize_database('$NODE_IP', '$ATOMA_API_KEY');\""

echo "ATOMA_API_URL=http://$PROXY_IP:8080" >> $GITHUB_ENV