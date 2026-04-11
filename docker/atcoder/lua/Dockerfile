FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG LUA_VERSION=5.4.7

WORKDIR /judge

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates curl libreadline-dev \
    && rm -rf /var/lib/apt/lists/*

# Build and install Lua from source
RUN curl -sL "https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" -o /tmp/lua.tar.gz \
    && tar -C /tmp -xzf /tmp/lua.tar.gz \
    && cd /tmp/lua-${LUA_VERSION} \
    && make all test \
    && make install \
    && rm -rf /tmp/lua*
