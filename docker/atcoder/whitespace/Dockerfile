FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

# whitespace-rs 1.3.0 has no aarch64 JIT backend; `main.rs` unconditionally calls
# `jit_aot()` and aarch64 builds fail at compile time. amd64-only (same precedent
# as Crystal/NASM).
# Build/run with: docker build --platform linux/amd64 / docker run --platform linux/amd64

ARG WHITESPACERS_COMMIT=5e496ec7c2a56569f9169471519b5071b4e6444b

WORKDIR /judge

# Install build dependencies.
# rustup is pulled from Ubuntu 24.04 APT (matches TOML `apt install rustup`) and is
# purged in a later step once the binary has been built.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        rustup \
    && rm -rf /var/lib/apt/lists/*

# rustup reads these env vars to place its state under /tmp so the toolchain can be
# removed cleanly after the build finishes.
ENV CARGO_HOME=/tmp/.cargo
ENV RUSTUP_HOME=/tmp/.rustup

# Install the stable Rust toolchain (matches TOML: `rustup default stable`, not pinned)
# and build the `wsc` binary from the pinned upstream commit. `--root /usr/local` drops
# the binary directly into /usr/local/bin. No `--locked`: upstream ships no Cargo.lock
# and the TOML does not pass it either.
RUN rustup default stable \
    && cargo install --git https://github.com/CensoredUsername/whitespace-rs --rev ${WHITESPACERS_COMMIT} --root /usr/local \
    && rm -rf /tmp/.cargo /tmp/.rustup

# Purge rustup (matches TOML: `sudo apt purge -y rustup`). build-essential is intentionally
# kept to follow the existing project pattern.
RUN apt-get update \
    && apt-get purge -y rustup \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: reproduce the TOML compile+run commands end-to-end with a minimal program
# consisting of a single EndProgram instruction (LF LF LF).
RUN printf '\n\n\n' > Main.ws \
    && wsc --dump Main.dump Main.ws \
    && test -s Main.dump \
    && wsc Main.ws \
    && rm -f Main.ws Main.dump
