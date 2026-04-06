FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

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
