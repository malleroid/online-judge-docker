FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG FACTOR_VERSION=0.100
ARG FACTOR_SHA256=c66be5e2f2547235b73da648b3e569af1b47699b4d3ead28b83f01d22bfaa006

# Factor 0.100 only provides x86_64 Linux prebuilt binaries; release notes state
# ARM64 support is incomplete. Build with: docker build --platform linux/amd64
# Upstream GitHub Release tarball is used (byte-for-byte identical to
# downloads.factorcode.org, but served over HTTPS with a stable sha256 pin).

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/factor.tar.gz \
        "https://github.com/factor/factor/releases/download/${FACTOR_VERSION}/factor-linux-x86-64-${FACTOR_VERSION}.tar.gz" \
    && echo "${FACTOR_SHA256}  /tmp/factor.tar.gz" | sha256sum -c - \
    && tar -C /opt -xzf /tmp/factor.tar.gz \
    && rm /tmp/factor.tar.gz

ENV PATH="/opt/factor:${PATH}"

# Smoke test: run a minimal Factor program with the TOML execution command
RUN printf 'USING: io ;\nIN: main\n\n"smoke-ok" print\n' > /tmp/Main.factor \
    && cd /tmp \
    && /opt/factor/factor -datastack=102400 -retainstack=102400 -callstack=102400 -callbacks=102400 Main.factor | tee /tmp/smoke.out \
    && grep -q '^smoke-ok$' /tmp/smoke.out \
    && rm /tmp/Main.factor /tmp/smoke.out
