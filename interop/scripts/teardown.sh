#!/bin/bash
set -e

# Read instance IDs from file
read NODE_INSTANCE_ID PROXY_INSTANCE_ID < instance_ids.txt

# Terminate instances
echo "Terminating instances..."
aws ec2 terminate-instances --instance-ids $NODE_INSTANCE_ID $PROXY_INSTANCE_ID

# Wait for instances to terminate
echo "Waiting for instances to terminate..."
aws ec2 wait instance-terminated --instance-ids $NODE_INSTANCE_ID $PROXY_INSTANCE_ID

# Optionally delete security group and key pair
# TODO: Remove the commented out code once we have a proper release
# aws ec2 delete-security-group --group-name atoma-sg
# aws ec2 delete-key-pair --key-name atoma-key

echo "Cleanup complete."