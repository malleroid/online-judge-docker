FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG GAUCHE_VERSION=0.9.15

WORKDIR /judge

# Install Gauche using the official get-gauche.sh installer
# Matches TOML: build-essential libgdbm-dev zlib1g-dev texinfo + get-gauche.sh
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential libgdbm-dev zlib1g-dev texinfo \
       ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/shirok/get-gauche/master/get-gauche.sh \
       -o /tmp/get-gauche.sh \
    && cd /tmp \
    && bash get-gauche.sh --auto --skip-tests --prefix /usr/local --version ${GAUCHE_VERSION} \
    && rm -rf /tmp/get-gauche.sh /tmp/Gauche-${GAUCHE_VERSION}*
