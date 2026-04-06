FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

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
