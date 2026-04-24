FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

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
