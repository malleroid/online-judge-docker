FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GNUCOBOL_VERSION=3.2

WORKDIR /judge

# Install build and runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates libcjson-dev libdb-dev libgmp-dev libxml2-dev wget \
    && rm -rf /var/lib/apt/lists/*

# Build and install GnuCOBOL from source
RUN wget -q "https://downloads.sourceforge.net/project/gnucobol/gnucobol/${GNUCOBOL_VERSION}/gnucobol-${GNUCOBOL_VERSION}.tar.xz" \
        -O /tmp/gnucobol.tar.xz \
    && mkdir /tmp/gnucobol \
    && tar -C /tmp/gnucobol --strip-components=1 -xf /tmp/gnucobol.tar.xz \
    && cd /tmp/gnucobol \
    && ./configure \
    && make -j"$(nproc)" \
    && make install \
    && ldconfig \
    && rm -rf /tmp/gnucobol /tmp/gnucobol.tar.xz
