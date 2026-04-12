FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG HAXE_VERSION=4.3.7
ARG NEKO_VERSION=2-4-1

# Haxe linux64 binary is x86_64 only; no arm64 support
# Build with: docker build --platform linux/amd64

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

WORKDIR /judge

# Set timezone
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime \
    && echo Etc/UTC > /etc/timezone

# Install build dependencies for Neko + system packages
RUN apt-get update \
    && apt-get install -y \
        apache2-dev build-essential ca-certificates cmake git \
        libgc-dev libgtk-3-dev libmariadb-dev-compat libmbedtls-dev \
        libpcre2-dev libsqlite3-dev libssl-dev \
        openjdk-21-jdk-headless wget zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Build and install Neko VM
RUN wget -q "https://github.com/HaxeFoundation/neko/archive/refs/tags/v${NEKO_VERSION}.tar.gz" \
        -O /tmp/neko.tar.gz \
    && tar -C /tmp -xf /tmp/neko.tar.gz \
    && mkdir /tmp/neko-${NEKO_VERSION}/build \
    && cd /tmp/neko-${NEKO_VERSION}/build \
    && cmake .. \
    && make \
    && make install \
    && rm -rf /tmp/neko*

# Install Haxe binary
RUN wget -q "https://github.com/HaxeFoundation/haxe/releases/download/${HAXE_VERSION}/haxe-${HAXE_VERSION}-linux64.tar.gz" \
        -O /tmp/haxe.tar.gz \
    && mkdir -p /opt/haxe \
    && tar -C /opt/haxe --strip-components=1 -xf /tmp/haxe.tar.gz \
    && rm /tmp/haxe.tar.gz

ENV PATH="/opt/haxe:${PATH}"
ENV HAXE_STD_PATH=/opt/haxe/std

# Install haxelib libraries
RUN mkdir -p ${HOME}/haxelib \
    && haxelib setup ${HOME}/haxelib \
    && wget -q "https://github.com/fal-works/wronganswer/archive/refs/tags/v0.3.0.zip" -O /tmp/wronganswer.zip \
    && haxelib install /tmp/wronganswer.zip \
    && haxelib install hxjava 4.2.0 \
    && rm /tmp/wronganswer.zip

# Copy execution wrapper script
COPY java.sh java.sh
