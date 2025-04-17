# AWS Deployment Scripts

This folder contains scripts for deploying and managing AWS instances for the Atoma Network interop tests. These scripts automate the process of setting up the necessary infrastructure for running the node and proxy services.

## Prerequisites

- **AWS CLI**: Must be installed and configured with appropriate credentials
  ```bash
  # Install AWS CLI
  pip install awscli

  # Configure AWS CLI
  aws configure
  ```
- **GitHub Secrets**: All required secrets must be set in your GitHub repository

## ⚠️ IMPORTANT: Cost Management

**CRITICAL**: These scripts launch AWS EC2 instances that will incur charges. It is **ABSOLUTELY CRITICAL** that you run the teardown script after testing to avoid unnecessary charges. AWS resources, especially GPU instances, can be expensive.

```bash
# Always run this after testing to avoid charges
./teardown.sh
```

## Overview

The deployment process consists of the following steps:

1. **Create Configuration Files**: Generate necessary configuration files from GitHub secrets
2. **Deploy AWS Infrastructure**: Launch EC2 instances for the node and proxy
3. **Configure Instances**: Set up Docker, clone repositories, and configure services
4. **Start Services**: Launch the Atoma node and proxy services
5. **Run Tests**: Execute the interop tests against the deployed infrastructure
6. **Collect Logs**: Gather logs from both instances for debugging
7. **Teardown**: Clean up AWS resources to avoid unnecessary costs

## Key Scripts

- `create_files.sh`: Creates configuration files from GitHub secrets
- `deploy.sh`: Deploys AWS infrastructure and configures instances
- `node_setup.sh`: Sets up the node instance (runs on the instance)
- `proxy_setup.sh`: Sets up the proxy instance (runs on the instance)
- `print_docker_logs.sh`: Collects Docker logs from both instances
- `teardown.sh`: Cleans up AWS resources

## Deployment Process

The `deploy.sh` script performs the following actions:

1. **Infrastructure Setup**:
   - Creates a key pair for SSH access
   - Creates a security group with necessary port permissions
   - Launches EC2 instances for the node and proxy

2. **Instance Configuration**:
   - Copies configuration files to the instances
   - Sets up Docker and other dependencies
   - Clones the necessary repositories
   - Configures the services

3. **Service Startup**:
   - Starts the Atoma proxy service
   - Starts the Atoma node service with the specified profiles

## Useful Commands for Debugging

### Checking Instance Information

```bash
# Get public IPs of instances
aws ec2 describe-instances --instance-ids $INSTANCE_IDS --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
```

### SSH Access

```bash
# SSH into an instance
ssh -i atoma-key.pem -o StrictHostKeyChecking=no ubuntu@<INSTANCE_IP>
```

### Database Management

```bash
# Access the PostgreSQL database
sudo docker exec -it atoma-proxy-db-1 psql -U atoma -d atoma

# Update node public address
UPDATE nodes SET public_address = 'http://<NODE_IP>:3000' WHERE node_small_id = 1;

# Add API token
INSERT INTO api_tokens (user_id, token, name) VALUES (1, '<TOKEN>', '<NAME>');

# Add balance
INSERT INTO balance (user_id, usdc_balance) VALUES (1, 10000000000000);
```

### File Operations

```bash
# Download a file from an instance
sudo scp -i atoma-key.pem ubuntu@<INSTANCE_IP>:/path/to/file ./local/path

# Upload a file to an instance
sudo scp -i atoma-key.pem ./local/file ubuntu@<INSTANCE_IP>:/path/to/destination
```

### Docker Operations

```bash
# View Docker logs
sudo docker logs <CONTAINER_NAME>

# Access a running container
sudo docker exec -it <CONTAINER_NAME> /bin/bash

# Restart a service
sudo docker compose -f docker-compose.dev.yaml restart <SERVICE_NAME>
```

## Debugging NVIDIA Access

```bash
 sudo docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
 ```

## Important Notes

- **Cost Management**: AWS resources can be expensive. Always run the teardown script after testing to avoid unnecessary charges.
- **Security**: The scripts use a security group that allows access from anywhere (0.0.0.0/0). For production environments, restrict access to specific IP ranges.
- **Secrets**: Configuration files are created from GitHub secrets. Make sure all required secrets are set in your repository.

## Troubleshooting

If you encounter issues with the deployment:

1. Check the AWS console for instance status
2. SSH into the instances and check the logs
3. Use the `print_docker_logs.sh` script to collect logs from both instances
4. Verify that all required secrets are set in GitHub

For vllm-cpu specific issues:
- Ensure sufficient memory is available (at least 8GB recommended)
- Check that the `CHAT_COMPLETIONS_MAX_MODEL_LEN` environment variable is set
- Verify that the model is compatible with CPU-only execution


```bash
aws ec2 describe-instances --instance-ids $INSTANCE_IDS --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
```

```bash
ssh -i atoma-key.pem -o StrictHostKeyChecking=no ubuntu@$AWS_INSTANCE_IP
```

```bash
 sudo docker exec -it atoma-proxy-db-1 psql -U atoma -d atoma
 ```