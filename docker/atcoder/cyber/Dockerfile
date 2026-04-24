FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG CYBER_VERSION=0.3
ARG CYBER_SHA256=24343c64e6c249fc2c081d11d959ad0e1db612f534e0a891c96db6111d9a3e1d

# Cyber 0.3 only publishes an x86_64 Linux release asset (cyber-linux-x64.tar.gz)
# and its source build pins a specific Zig toolchain; no arm64 binary is available.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Download the official GitHub Release tarball (flat archive containing a single
# `cyber` binary at the root) and install it into /usr/local/bin. We bypass the
# upstream install.sh so the sha256 pin is enforced at build time.
RUN curl -fsSL -o /tmp/cyber.tar.gz \
        "https://github.com/fubark/cyber/releases/download/${CYBER_VERSION}/cyber-linux-x64.tar.gz" \
    && echo "${CYBER_SHA256}  /tmp/cyber.tar.gz" | sha256sum -c - \
    && tar -C /usr/local/bin -xzf /tmp/cyber.tar.gz \
    && chmod +x /usr/local/bin/cyber \
    && rm /tmp/cyber.tar.gz

# Smoke test: exercise the TOML compile + execute flow.
RUN printf "print 'smoke-ok'\n" > Main.cy \
    && cyber compile Main.cy \
    && test "$(cyber Main.cy)" = "smoke-ok" \
    && rm Main.cy
