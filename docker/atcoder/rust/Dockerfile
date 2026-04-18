FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG RUST_VERSION=1.89.0
ARG RUST_CHANNEL=1.89.0
ARG ATCODER_PROPOSAL_COMMIT=7a724cdf84202ce3bef84527676e2c398bca7b6e

WORKDIR /judge

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Install Rust via standalone installer
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN RUST_TARGET=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64-unknown-linux-gnu" || echo "x86_64-unknown-linux-gnu") \
    && curl "https://static.rust-lang.org/dist/rust-${RUST_CHANNEL}-${RUST_TARGET}.tar.gz" \
        -fo /tmp/rust.tar.gz \
    && tar xf /tmp/rust.tar.gz -C /tmp \
    && /tmp/rust-${RUST_CHANNEL}-${RUST_TARGET}/install.sh \
    && rm -rf /tmp/rust*

# Set up project structure
COPY .cargo/config.toml .cargo/config.toml
COPY Cargo.toml Cargo.toml

# Download pinned Cargo.lock
RUN curl "https://raw.githubusercontent.com/rust-lang-ja/atcoder-proposal/${ATCODER_PROPOSAL_COMMIT}/Cargo.lock" \
        -fo Cargo.lock

# Pre-build all crates with dummy main.rs
RUN mkdir -p src \
    && echo 'fn main() {}' > src/main.rs \
    && cargo build --release \
    && rm target/release/main

ENV RUST_BACKTRACE=0
