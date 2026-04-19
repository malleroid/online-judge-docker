FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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

# Build and install fishr from upstream HEAD
# TOML pins no commit and no version, so we follow the same policy (CLAUDE.md:
# "upstream に tag なし、patch なし、TOML も pin してない → HEAD clone").
RUN git clone https://github.com/noirotm/fishr /tmp/fishr \
    && cd /tmp/fishr \
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
