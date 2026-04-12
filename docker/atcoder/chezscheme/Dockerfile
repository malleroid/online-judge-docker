FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG CHEZ_VERSION=10.2.0

WORKDIR /judge

# Build and install ChezScheme from source
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates wget \
    && mkdir /tmp/chez-install \
    && cd /tmp/chez-install \
    && wget -q "https://github.com/cisco/ChezScheme/releases/download/v${CHEZ_VERSION}/csv${CHEZ_VERSION}.tar.gz" \
    && tar xf "csv${CHEZ_VERSION}.tar.gz" \
    && cd "csv${CHEZ_VERSION}" \
    && ./configure --disable-curses --disable-x11 --installprefix=/usr/local \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/chez-install \
    && rm -rf /var/lib/apt/lists/*

# Install SRFI library
RUN apt-get update \
    && apt-get install -y --no-install-recommends scheme-chez-srfi \
    && rm -rf /var/lib/apt/lists/*

ENV CHEZSCHEMELIBDIRS=.:/usr/share/r6rs
