FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG PIET_VERSION=3.0.0
ARG PIET_SHA256=67e0ee0b5660e5e3477b777db99ab0af5bc8eb77f0bb7c9614023740db0ed676

WORKDIR /judge

# Install build dependencies.
# rustup is pulled from Ubuntu 24.04 APT (matches TOML `apt install rustup`) and is
# purged in a later step once the binary has been built.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        rustup \
    && rm -rf /var/lib/apt/lists/*

# rustup reads these env vars to place its state under /tmp so the toolchain can be
# removed cleanly after the build finishes.
ENV CARGO_HOME=/tmp/.cargo
ENV RUSTUP_HOME=/tmp/.rustup

# Install the stable Rust toolchain (matches TOML: `rustup default stable`, not pinned),
# download the Piet 3.0.0 source tarball with sha256 verification, and build/install the
# `piet_programming_language` binary via `cargo install --locked` so the pinned Cargo.lock
# from upstream is honoured regardless of toolchain patch bumps.
RUN rustup default stable \
    && curl -fsSL -o /tmp/piet.tar.gz \
        "https://github.com/your-diary/piet_programming_language/archive/refs/tags/v${PIET_VERSION}.tar.gz" \
    && echo "${PIET_SHA256}  /tmp/piet.tar.gz" | sha256sum -c - \
    && tar -C /tmp -xzf /tmp/piet.tar.gz \
    && cargo install --locked --path /tmp/piet_programming_language-${PIET_VERSION} \
    && cp /tmp/.cargo/bin/piet_programming_language /usr/local/bin/ \
    && rm -rf /tmp/piet.tar.gz /tmp/piet_programming_language-${PIET_VERSION} /tmp/.cargo /tmp/.rustup

# Purge rustup (matches TOML: `sudo apt purge -y rustup`). build-essential is intentionally
# kept to follow the existing project pattern.
RUN apt-get update \
    && apt-get purge -y rustup \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: reproduce the TOML compile command end-to-end with a minimal 1x1 white P3 PPM.
RUN printf 'P3\n1 1\n255\n255 255 255\n' > Main.ppm \
    && piet_programming_language --max-iter 0 Main.ppm \
    && touch ok \
    && test -f ok \
    && rm -f Main.ppm ok
