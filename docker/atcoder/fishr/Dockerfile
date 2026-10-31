FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG FISHR_SHA=c86262b5e233815ece7a44c7810817f738c6c7d3

WORKDIR /judge

# Install build dependencies
# - rustc, cargo: build fishr from source (matches TOML: `apt install rustc cargo git`)
# - git: clone the fishr repository
# - ca-certificates: HTTPS for git clone
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cargo \
        git \
        rustc \
    && rm -rf /var/lib/apt/lists/*

# Build and install fishr
# The TOML clones HEAD with no commit or version pin. Upstream HEAD later
# moved to Rust edition 2024, which Ubuntu 24.04's cargo 1.75 cannot build,
# so we pin to the SHA current at 2025-10-18 (AtCoder 2025/10 announcement
# date), matching clay / jule.
RUN git clone https://github.com/noirotm/fishr /tmp/fishr \
    && cd /tmp/fishr \
    && git checkout "${FISHR_SHA}" \
    && cargo build --release \
    && cp target/release/fishr /usr/local/bin/fishr \
    && rm -rf /tmp/fishr /root/.cargo

# Smoke test: reproduce the TOML execution command end-to-end.
# Program: "A"o; → push 'A' in string mode, output as char, halt.
RUN printf '%s' '"A"o;' > /tmp/Main.fish \
    && cd /tmp \
    && OUT=$(fishr Main.fish) \
    && echo "smoke test output: ${OUT}" \
    && [ "${OUT}" = "A" ] \
    && rm /tmp/Main.fish
