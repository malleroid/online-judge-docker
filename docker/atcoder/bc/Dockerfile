FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG BC_VERSION=1.08.2

WORKDIR /judge

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates lzip texinfo wget \
    && rm -rf /var/lib/apt/lists/*

# Build and install GNU bc from source
RUN wget -q "https://ftpmirror.gnu.org/gnu/bc/bc-${BC_VERSION}.tar.lz" -O /tmp/bc.tar.lz \
    && mkdir /tmp/bc \
    && tar --lzip -C /tmp/bc --strip-components=1 -xf /tmp/bc.tar.lz \
    && cd /tmp/bc \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/bc /tmp/bc.tar.lz
