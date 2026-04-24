FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG TARGETARCH
ARG DUCKDB_VERSION=1.3.2

WORKDIR /judge

# Install wget
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

# Install DuckDB CLI from GitHub Releases
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN DUCKDB_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") \
    && wget -q "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/duckdb_cli-linux-${DUCKDB_ARCH}.gz" \
        -O /tmp/duckdb.gz \
    && gunzip /tmp/duckdb.gz \
    && install /tmp/duckdb /usr/local/bin/duckdb \
    && rm /tmp/duckdb
