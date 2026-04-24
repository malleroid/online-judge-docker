FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG CRYSTAL_VERSION=1.17.0
ARG CRYSTAL_SHA256=9fa1c66cf10ecaf221a1dcbcefa76d564da1653cb5bc4606a2d5143aa4da8ad0

# Crystal 1.17 only provides x86_64 Linux binaries; no arm64 support
# Build with: docker build --platform linux/amd64

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        git \
        libatlas-base-dev \
        libc6-dev \
        libgsl-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/crystal.tar.gz \
        "https://github.com/crystal-lang/crystal/releases/download/${CRYSTAL_VERSION}/crystal-${CRYSTAL_VERSION}-1-linux-x86_64-bundled.tar.gz" \
    && echo "${CRYSTAL_SHA256}  /tmp/crystal.tar.gz" | sha256sum -c - \
    && tar -C /opt -xzf /tmp/crystal.tar.gz \
    && ln -s /opt/crystal-${CRYSTAL_VERSION}-1/bin/crystal /usr/local/bin/crystal \
    && ln -s /opt/crystal-${CRYSTAL_VERSION}-1/bin/shards /usr/local/bin/shards \
    && rm /tmp/crystal.tar.gz

# Create Crystal project
RUN mkdir main \
    && cd main \
    && crystal init app .

# Add library dependencies and install
COPY shard-deps.yml /tmp/shard-deps.yml
RUN cd main \
    && cat /tmp/shard-deps.yml >> shard.yml \
    && shards install --verbose \
    && rm /tmp/shard-deps.yml
