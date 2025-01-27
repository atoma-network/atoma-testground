# Variables
REPO_URL = https://github.com/atoma-network/atoma-proxy.git
CLONE_DIR = atoma-proxy
DOCKERFILE = Dockerfile
CHECKSUM_FILE = checksums.txt

# Default target
.PHONY: all
all: clean clone verify build

# Clean previous build artifacts
.PHONY: clean
clean:
	rm -rf $(CLONE_DIR)
	rm -f $(CHECKSUM_FILE)

# Clone the repository
.PHONY: clone
clone:
	git clone $(REPO_URL) $(CLONE_DIR)

# Download and verify checksums
.PHONY: verify
verify:
	cd $(CLONE_DIR) && \
	git rev-parse HEAD > ../${CHECKSUM_FILE} && \
	echo "Repository cloned at commit: $$(cat ../${CHECKSUM_FILE})"

# Build using Docker
.PHONY: build
build:
	docker build \
		--build-arg TRACE_LEVEL=info \
		-f $(CLONE_DIR)/$(DOCKERFILE) \
		-t atoma-node:latest \
		$(CLONE_DIR)

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all     - Clean, clone, verify and build (default)"
	@echo "  clean   - Remove build artifacts"
	@echo "  clone   - Clone the repository"
	@echo "  verify  - Verify repository checksum"
	@echo "  build   - Build Docker image"
	@echo "  help    - Show this help message"
