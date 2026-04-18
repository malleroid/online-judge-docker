FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
