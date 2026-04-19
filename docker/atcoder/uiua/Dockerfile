FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG UIUA_VERSION=0.16.2
ARG UIUA_SHA256=2425bb7428d82bb11314621f0d19e89d8fe957aa72cd7cd142043f5c4fb8471b

# Uiua 0.16.2 only publishes an x86_64 Linux binary (the -no-audio variant used
# by the AtCoder TOML); no aarch64 Linux release asset exists upstream.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Fetch the upstream release zip, verify sha256, and install the single `uiua`
# binary under /opt/uiua with a symlink in /usr/local/bin.
RUN curl -fsSL -o /tmp/uiua.zip \
        "https://github.com/uiua-lang/uiua/releases/download/${UIUA_VERSION}/uiua-bin-x86_64-unknown-linux-gnu-no-audio.zip" \
    && echo "${UIUA_SHA256}  /tmp/uiua.zip" | sha256sum -c - \
    && mkdir -p /opt/uiua \
    && unzip -q /tmp/uiua.zip -d /opt/uiua \
    && chmod +x /opt/uiua/uiua \
    && ln -s /opt/uiua/uiua /usr/local/bin/uiua \
    && rm /tmp/uiua.zip

# Smoke test: reproduce the TOML compile/execute flow end-to-end. `&pf` is the
# raw-print system function that writes its string argument with no trailing
# newline, so the output should match "smoke-ok" exactly.
RUN cd /tmp \
    && printf '%s' '&pf "smoke-ok"' > Main.ua \
    && uiua check Main.ua \
    && out="$(uiua run --no-format --no-color Main.ua)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f Main.ua

# Purge fetch-only deps. ca-certificates stays for any runtime TLS use.
RUN apt-get purge -y --auto-remove curl unzip \
    && rm -rf /var/lib/apt/lists/*
