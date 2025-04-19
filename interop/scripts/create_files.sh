#!/bin/bash
set -e

# Create config.toml from secret
echo "${NODE_CONFIG}" > config.toml

# Create config.proxy.toml from secret
echo "${PROXY_CONFIG}" > config.proxy.toml

mkdir -p sui_config
echo "${SUI_CLIENT_YAML}" > sui_config/client.yaml
echo "${SUI_ALIASES}" > sui_config/sui.aliases
echo "${SUI_KEYSTORE}" > sui_config/sui.keystore

mkdir -p data
echo "${NODE_LOCAL_KEY}" > data/node_local_key
chmod 400 data/node_local_key
echo "${PROXY_LOCAL_KEY}" > data/proxy_local_key
chmod 400 data/proxy_local_key

# Create .env from secret
echo "${NODE_ENV}" > .env

# Create .proxy.env from secret
echo "${PROXY_ENV}" > .proxy.env

echo "Configuration files created successfully!"
