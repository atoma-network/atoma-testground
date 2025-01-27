# Pre-download models to a shared volume
docker run -v /shared/models:/models \
           -e HF_TOKEN=$(aws secretsmanager get-secret-value --secret-id HF_TOKEN) \
           huggingface/transformers:latest \
           huggingface-cli download --repo-id {model} --local-dir /models