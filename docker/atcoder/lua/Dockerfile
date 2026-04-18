FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
