# Builder stage
FROM --platform=$BUILDPLATFORM rust:1.83-slim-bullseye AS builder

# Add platform-specific arguments
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETARCH

# Trace level argument
ARG TRACE_LEVEL=info
ARG PROFILE

# Install build dependencies
RUN apt-get update && apt-get install -y \
	build-essential \
	pkg-config \
	libssl-dev \
	curl \
	git \
	&& rm -rf /var/lib/apt/lists/*


# Initialize and update git submodules
RUN git submodule init && git submodule update --recursive

# Save git commit hash
RUN git rev-parse HEAD > /usr/src/checksum.txt

# Compile
RUN if [ "$PROFILE" = "cloud" ]; then \
	RUST_LOG=${TRACE_LEVEL} cargo build --release --bin atoma-infer --features google-oauth; \
	else \
	RUST_LOG=${TRACE_LEVEL} cargo build --release --bin atoma-infer; \
	fi

# Final stage
FROM --platform=$TARGETPLATFORM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
	ca-certificates \
	libssl1.1 \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/logs

# Copy the built binary and checksum from builder stage
COPY --from=builder /usr/src/target/release/atoma-infer /usr/local/bin/atoma-infer
COPY --from=builder /usr/src/checksum.txt /app/checksum.txt

# Set executable permissions
RUN chmod +x /usr/local/bin/atoma-infer

# Copy and set up entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/local/bin/atoma-infer", "--config-path", "/app/config.toml"]
