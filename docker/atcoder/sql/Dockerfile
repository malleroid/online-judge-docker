FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
