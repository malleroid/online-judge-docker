FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG BASH_VERSION=5.3

WORKDIR /judge

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

# Build and install Bash from source
RUN wget -q -O /tmp/bash.tar.gz "https://ftp.gnu.org/gnu/bash/bash-${BASH_VERSION}.tar.gz" \
    && mkdir /tmp/bash \
    && tar -C /tmp/bash --strip-components=1 -xf /tmp/bash.tar.gz \
    && cd /tmp/bash \
    && ./configure --enable-largefile --without-bash-malloc \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/bash /tmp/bash.tar.gz
