FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG BABASHKA_VERSION=1.12.208

WORKDIR /judge

# Install curl for babashka installer
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Install babashka
RUN curl -sL https://raw.githubusercontent.com/babashka/babashka/master/install -o /tmp/install \
    && chmod +x /tmp/install \
    && /tmp/install --version ${BABASHKA_VERSION} \
    && rm /tmp/install
