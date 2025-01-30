#!/bin/bash

# Default root path
DATA_ROOT="${1:-/var/lib}"

# Array of directories to create
DIRECTORIES=(
    "${DATA_ROOT}/atoma-proxy/data"
    "${DATA_ROOT}/atoma-node/data"
    "${DATA_ROOT}/atoma-node/model-cache"
    "${DATA_ROOT}/atoma-node/logs"
)

# Create directories and set permissions
for dir in "${DIRECTORIES[@]}"; do
    echo "Creating directory: $dir"
    sudo mkdir -p "$dir"

    # Set appropriate permissions (adjust as needed)
    sudo chown -R 1000:1000 "$dir"
    sudo chmod -R 755 "$dir"
done

echo "Directory setup complete!"
echo "Created directories:"
for dir in "${DIRECTORIES[@]}"; do
    echo "- $dir"
done