FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG CARP_VERSION=0.5.5
ARG CARP_SHA256=886f6de92e75a06612474602ef6022609e51696465217abe5947296721448e69

# Carp 0.5.5 only provides x86_64 Linux binaries; no arm64 support
# Build with: docker build --platform linux/amd64

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/carp.zip \
        "https://github.com/carp-lang/Carp/releases/download/v${CARP_VERSION}/carp-v${CARP_VERSION}-x86_64-linux.zip" \
    && echo "${CARP_SHA256}  /tmp/carp.zip" | sha256sum -c - \
    && unzip -d /opt /tmp/carp.zip \
    && ln -s /opt/carp-v${CARP_VERSION}-x86_64-linux/bin/carp /usr/local/bin/carp \
    && rm /tmp/carp.zip

ENV CARP_DIR=/opt/carp-v0.5.5-x86_64-linux

# Smoke test
RUN printf '%s' '(defn main [] (println* "smoke-ok"))' > Main.carp \
    && carp -b --optimize Main.carp \
    && test "$(./out/Untitled)" = "smoke-ok" \
    && rm -rf Main.carp out
