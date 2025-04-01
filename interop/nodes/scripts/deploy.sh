#!/bin/bash
set -e

# Variables
REGION="us-west-2"
NODE_INSTANCE_TYPE="c5.2xlarge"  # Good for CPU workloads
PROXY_INSTANCE_TYPE="t3.medium"  # Sufficient for proxy
AMI_ID="ami-03f8acd418785369b"  # Ubuntu 22.04 LTS
KEY_NAME="atoma-key"
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

  # Allow Docker ports for node
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 3001 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 4001 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol udp --port 4001 --cidr 0.0.0.0/0

  # Allow Docker ports for proxy
  aws ec2 authorize-security-group-ingress --no-cli-pager --group-id $SECURITY_GROUP_ID --protocol tcp --port 8080-8083 --cidr 0.0.0.0/0

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
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=atoma-proxy}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids $NODE_INSTANCE_ID $PROXY_INSTANCE_ID

# Get public IPs
NODE_IP=$(aws ec2 describe-instances --instance-ids $NODE_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
PROXY_IP=$(aws ec2 describe-instances --instance-ids $PROXY_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo "Atoma Node IP: $NODE_IP"
echo "Atoma Proxy IP: $PROXY_IP"

# Wait a bit for the instances to be ready for SSH
echo "Waiting for SSH to be available..."
sleep 30

# Copy configuration files to the node instance
echo "Copying configuration files to node instance..."
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem .env ubuntu@$NODE_IP:/home/ubuntu/
scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem config.toml ubuntu@$NODE_IP:/home/ubuntu/

# Move files to the correct location using SSH
echo "Moving files to /opt/atoma..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ubuntu@$NODE_IP 'sudo mv /home/ubuntu/.env /opt/atoma/ && sudo mv /home/ubuntu/config.toml /opt/atoma/'

# Save instance IDs for cleanup
echo "$NODE_INSTANCE_ID $PROXY_INSTANCE_ID" > instance_ids.txt

# Output information for GitHub actions
echo "NODE_IP=$NODE_IP" >> $GITHUB_ENV
echo "PROXY_IP=$PROXY_IP" >> $GITHUB_ENV
echo "NODE_INSTANCE_ID=$NODE_INSTANCE_ID" >> $GITHUB_ENV
echo "PROXY_INSTANCE_ID=$PROXY_INSTANCE_ID" >> $GITHUB_ENV