FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

# Crystal only provides x86_64 binaries; no arm64 support
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# Install Crystal from OpenSUSE repository + dependencies
RUN apt-get update \
    && apt-get install -y ca-certificates curl gpg \
    && echo 'deb http://download.opensuse.org/repositories/devel:/languages:/crystal/xUbuntu_24.04/ /' \
        > /etc/apt/sources.list.d/crystal.list \
    && curl -fsSL https://download.opensuse.org/repositories/devel:languages:crystal/xUbuntu_24.04/Release.key \
        | gpg --dearmor > /etc/apt/trusted.gpg.d/crystal.gpg \
    && apt-get update \
    && apt-get install -y crystal1.17 git libatlas-base-dev libgsl-dev \
    && rm -rf /var/lib/apt/lists/*

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
