FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

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
