#!/bin/bash

# Check if .atoma_env exists
if [ ! -f .atoma.env ]; then
    echo "Error: .atoma.env file not found"
    exit 1
fi

# Source the environment variables
source .atoma.env

# Generate config.toml
cat > config.toml << EOF
[atoma_sui]
atoma_db                = "${ATOMA_DB_ID}"
atoma_package_id        = "${ATOMA_PACKAGE_ID}"
cursor_path            = "${CURSOR_PATH:-"./cursor.toml"}"
http_rpc_node_addr     = "${SUI_RPC_NODE:-"https://fullnode.testnet.sui.io:443"}"
limit                  = ${REQUEST_LIMIT:-100}
max_concurrent_requests = ${MAX_CONCURRENT_REQUESTS:-10}
request_timeout        = { secs = ${REQUEST_TIMEOUT_SECS:-300}, nanos = ${REQUEST_TIMEOUT_NANOS:-0} }
sui_config_path        = "${SUI_CONFIG_PATH:-"/root/.sui/sui_config/client.yaml"}"
sui_keystore_path      = "${SUI_KEYSTORE_PATH:-"/root/.sui/sui_config/sui.keystore"}"
usdc_package_id        = "${USDC_PACKAGE_ID}"

[atoma_state]
database_url = "${ATOMA_STATE_DATABASE_URL:-"postgresql://atoma:atoma@db:5432/atoma"}"

[atoma_service]
hf_token             = "${HF_TOKEN}"
modalities           = [ ${MODALITIES:-'[ "Chat Completions" ]'} ]
models               = [ "${MODELS:-"TinyLlama/TinyLlama-1.1B-Chat-v1.0"}" ]
password             = "${SERVICE_PASSWORD:-"password"}"
revisions           = [ "${MODEL_REVISIONS:-"main"}" ]
service_bind_address = "${SERVICE_BIND_ADDRESS:-"0.0.0.0:8080"}"

[atoma_proxy_service]
service_bind_address = "${PROXY_BIND_ADDRESS:-"0.0.0.0:8081"}"

[atoma_auth]
access_token_lifetime  = ${ACCESS_TOKEN_LIFETIME:-1}
google_client_id      = "${GOOGLE_CLIENT_ID:-""}"
refresh_token_lifetime = ${REFRESH_TOKEN_LIFETIME:-1}
secret_key            = "${AUTH_SECRET_KEY:-"secret_key"}"

[atoma_p2p]
listen_address = "${P2P_LISTEN_ADDRESS:-"0.0.0.0:8080"}"
EOF

# Generate .env file for docker-compose
cat > .env << EOF
# Database Configuration
POSTGRES_DB=${POSTGRES_DB:-"atoma"}
POSTGRES_USER=${POSTGRES_USER:-"atoma"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"password"}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

# Service Configuration
TRACE_LEVEL=${TRACE_LEVEL:-"info"}
ATOMA_PROXY_CONFIG_PATH=${ATOMA_PROXY_CONFIG_PATH:-"./config.toml"}
ACME_EMAIL=${ACME_EMAIL:-""}

# Port Configuration
DASHBOARD_PORT=${DASHBOARD_PORT:-3000}
ATOMA_PROXY_SERVICE_PORT=${ATOMA_PROXY_SERVICE_PORT:-8081}
ATOMA_API_SERVICE_PORT=${ATOMA_API_SERVICE_PORT:-8080}
SUI_PROVER_SERVICE_PORT=${SUI_PROVER_SERVICE_PORT:-8082}

# Prover Configuration
ZKEY=${ZKEY:-"./binaries/zkLogin.zkey"}

# Monitoring Configuration
PROMETHEUS_PORT=${PROMETHEUS_PORT:-9090}
GRAFANA_PORT=${GRAFANA_PORT:-30001}
EOF

echo "Generated config.toml and .env files"