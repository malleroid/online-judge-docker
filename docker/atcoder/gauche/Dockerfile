FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
