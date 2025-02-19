# Variables
REPO_RAW_URL = https://raw.githubusercontent.com/atoma-network/atoma-node/main
DOCKERFILE = Dockerfile
DOCKER_COMPOSE = docker-compose.dev.yaml
# Default target
.PHONY: all
all: clean update build

# Clean previous build artifacts
.PHONY: clean
clean:
	rm -f $(DOCKER_COMPOSE)
	rm -f $(DOCKERFILE)

# Update files from repository
.PHONY: update
update:
	@echo "Downloading latest docker-compose.yaml..."
	@curl -f -s -S -o $(DOCKER_COMPOSE) $(REPO_RAW_URL)/$(DOCKER_COMPOSE) || (echo "Failed to download $(DOCKER_COMPOSE)" && exit 1)
	@echo "Successfully updated $(DOCKER_COMPOSE)"
	@mv $(DOCKER_COMPOSE) docker-compose.yaml
	@echo "Downloading latest Dockerfile..."
	@curl -f -s -S -o $(DOCKERFILE) $(REPO_RAW_URL)/$(DOCKERFILE) || (echo "Failed to download $(DOCKERFILE)" && exit 1)
	@echo "Successfully updated $(DOCKERFILE)"

# Generate configuration files
.PHONY: config
config:
	./generate-config.sh


# Run the local profile
.PHONY: build
build: update config
	COMPOSE_PROFILES=mistralrs-cpu,non-confidential docker compose up -d


# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all           - Clean, update files and build (default)"
	@echo "  clean         - Remove build artifacts"
	@echo "  update        - Update Dockerfile and docker-compose.yaml from repository"
	@echo "  setup         - Create required directories"
	@echo "  build         - Build Docker image"
	@echo "  run           - Run the local profile (foreground)"
	@echo "  run-detached  - Run the local profile (background)"
	@echo "  help          - Show this help message"
