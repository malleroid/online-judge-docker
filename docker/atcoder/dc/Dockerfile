FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

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
