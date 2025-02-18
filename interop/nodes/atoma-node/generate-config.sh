#!/bin/bash

# Check if .atoma.env exists
if [ ! -f .atoma.env ]; then
    echo "Error: .atoma.env file not found"
    exit 1
fi

# Source the environment variables
source .atoma.env

# Generate config.toml
cat > config.toml << EOF
[atoma_service]
chat_completions_service_urls = {"${CHAT_COMPLETIONS_MODEL:-"meta-llama/Llama-3.2-3B-Instruct"}" = "${ATOMA_SERVICE_CHAT_COMPLETIONS_URLS:-"http://chat-completions:8000"}"}
embeddings_service_url = "${ATOMA_SERVICE_EMBEDDINGS_URL:-"66.23.193.245:8080"}"
image_generations_service_url = "${ATOMA_SERVICE_IMAGE_GENERATIONS_URL:-"66.23.193.245:8080"}"
models = ["${ATOMA_SERVICE_MODELS:-"TinyLlama/TinyLlama-1.1B-Chat-v1.0"}"]
revisions = ["${ATOMA_SERVICE_REVISIONS:-"main"}"]
service_bind_address = "${ATOMA_SERVICE_BIND_ADDRESS:-"0.0.0.0:3000"}"

[atoma_sui]
http_rpc_node_addr = "${ATOMA_SUI_RPC_NODE:-"https://fullnode.testnet.sui.io:443"}"
atoma_db = "${ATOMA_SUI_DB}"
atoma_package_id = "${ATOMA_SUI_PACKAGE_ID}"
usdc_package_id = "${ATOMA_SUI_USDC_PACKAGE_ID}"
request_timeout = { secs = ${ATOMA_SUI_REQUEST_TIMEOUT_SECS:-300}, nanos = ${ATOMA_SUI_REQUEST_TIMEOUT_NANOS:-0} }
max_concurrent_requests = ${ATOMA_SUI_MAX_CONCURRENT_REQUESTS:-10}
limit = ${ATOMA_SUI_LIMIT:-100}
node_small_ids = [${ATOMA_SUI_NODE_SMALL_IDS:-1}]
sui_config_path = "${ATOMA_SUI_CONFIG_PATH:-"/root/.sui/sui_config/client.yaml"}"
sui_keystore_path = "${ATOMA_SUI_KEYSTORE_PATH:-"/root/.sui/sui_config/sui.keystore"}"
cursor_path = "${ATOMA_SUI_CURSOR_PATH:-"./cursor.toml"}"

[atoma_state]
database_url = "${ATOMA_STATE_DATABASE_URL:-"postgresql://atoma:atoma@db:5432/atoma"}"

[atoma_daemon]
service_bind_address = "${ATOMA_DAEMON_BIND_ADDRESS:-"0.0.0.0:3001"}"
node_badges = [
    [
        "0x268e6af9502dcdcaf514bb699c880b37fa1e8d339293bc4f331f2dde54180600",
        1,
    ],
]

[proxy_server]
proxy_address = "${PROXY_SERVER_ADDRESS:-"http://localhost:8080"}"
node_public_address = "${PROXY_SERVER_NODE_PUBLIC_ADDRESS:-"http://localhost:3002"}"
country = "${PROXY_SERVER_COUNTRY:-"JM"}"

[atoma_p2p]
heartbeat_interval = { secs = ${ATOMA_P2P_HEARTBEAT_INTERVAL_SECS:-30}, nanos = ${ATOMA_P2P_HEARTBEAT_INTERVAL_NANOS:-0} }
idle_connection_timeout = { secs = ${ATOMA_P2P_IDLE_TIMEOUT_SECS:-60}, nanos = ${ATOMA_P2P_IDLE_TIMEOUT_NANOS:-0} }
listen_addr = "${ATOMA_P2P_LISTEN_ADDR:-"/ip4/0.0.0.0/udp/4001/quic-v1"}"
node_small_id = ${ATOMA_P2P_NODE_SMALL_ID:-1}
public_url = "${ATOMA_P2P_PUBLIC_URL:-"https://atoma.chad.com"}"
bootstrap_nodes = [
    "QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN",
    "QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa",
    "QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb",
    "QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt",
    "12D3KooWKnDdG3iXw9eTFijk3EWSunZcFi54Zka4wmtqtt6rPxc"
]
country = "${ATOMA_P2P_COUNTRY:-"JM"}"
EOF

# Generate .env file
cat > .env << EOF
HF_CACHE_PATH=${HF_CACHE_PATH:-"~/.cache/huggingface"}
HF_TOKEN=${HF_TOKEN}   # required if you want to access a gated model
ATOMA_NODE_CONFIG_PATH=${ATOMA_NODE_CONFIG_PATH:-"./config.toml"}

# ----------------------------------------------------------------------------------
# atoma node configuration

# Postgres Configuration
POSTGRES_DB=${POSTGRES_DB:-"atoma"}
POSTGRES_USER=${POSTGRES_USER:-"atoma"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"password"}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

# Sui Configuration
SUI_CONFIG_PATH=${SUI_CONFIG_PATH:-"~/.sui/sui_config"}

# Atoma Node Service Configuration
ATOMA_SERVICE_PORT=${ATOMA_SERVICE_PORT:-3000}

# Docker Compose Profile Configuration
COMPOSE_PROFILES=${COMPOSE_PROFILES:-"chat_completions_vllm"}

# Tracing Configuration
TRACE_LEVEL=${TRACE_LEVEL:-"info"}

# Monitoring Configuration
PROMETHEUS_PORT=${PROMETHEUS_PORT:-9090}
GRAFANA_PORT=${GRAFANA_PORT:-30001}

# ----------------------------------------------------------------------------------
# chat completions server
CHAT_COMPLETIONS_SERVER_PORT=${CHAT_COMPLETIONS_SERVER_PORT:-50000}
CHAT_COMPLETIONS_MODEL=${CHAT_COMPLETIONS_MODEL:-"meta-llama/Llama-3.1-70B-Instruct"}
CHAT_COMPLETIONS_MAX_MODEL_LEN=${CHAT_COMPLETIONS_MAX_MODEL_LEN:-4096} # context length

# vllm backend
VLLM_ENGINE_ARGS=--model \${CHAT_COMPLETIONS_MODEL} --max-model-len \${CHAT_COMPLETIONS_MAX_MODEL_LEN}

# ----------------------------------------------------------------------------------
# embeddings server
EMBEDDINGS_SERVER_PORT=${EMBEDDINGS_SERVER_PORT:-50001}
EMBEDDINGS_MODEL=${EMBEDDINGS_MODEL:-"intfloat/multilingual-e5-large-instruct"}

# tei backend
TEI_IMAGE=${TEI_IMAGE:-"ghcr.io/huggingface/text-embeddings-inference:1.5"}

# ----------------------------------------------------------------------------------
# image generation server
IMAGE_GENERATIONS_SERVER_PORT=${IMAGE_GENERATIONS_SERVER_PORT:-50002}
IMAGE_GENERATIONS_MODEL=${IMAGE_GENERATIONS_MODEL:-"black-forest-labs/FLUX.1-schnell"}
IMAGE_GENERATIONS_ARCHITECTURE=${IMAGE_GENERATIONS_ARCHITECTURE:-"flux"}

# mistralrs backend
MISTRALRS_IMAGE=${MISTRALRS_IMAGE:-"ghcr.io/ericlbuehler/mistral.rs:cuda-80-0.3.1"}

# ----------------------------------------------------------------------------------
# TDX configuration
ENABLE_TDX=${ENABLE_TDX:-"false"}

VLLM_TENSOR_PARALLEL_SIZE=${VLLM_TENSOR_PARALLEL_SIZE:-1}
EOF

echo "Generated config.toml and .env files"