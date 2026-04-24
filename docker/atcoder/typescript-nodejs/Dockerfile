FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG TARGETARCH
ARG NODE_VERSION=22.19.0

WORKDIR /judge

# Install ansifilter (for compile error output filtering) and wget
RUN apt-get update \
    && apt-get install -y --no-install-recommends ansifilter ca-certificates wget xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js from official binary
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN NODE_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") \
    && wget -q -O /tmp/node.tar.xz \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
    && tar -C /usr/local --strip-components=1 -xf /tmp/node.tar.xz \
        --wildcards '*/bin' '*/share' '*/lib' '*/include' \
    && rm /tmp/node.tar.xz

# Node.js module resolution searches /node_modules from root
RUN ln -s /usr/local/lib/node_modules /node_modules

# Install TypeScript, type definitions, and libraries
RUN npm install -g \
    typescript@5.9.2 \
    @types/lodash@4.17.20 \
    @types/node@22.18.1 \
    ac-library-js@0.1.1 \
    data-structure-typed@2.0.4 \
    immutable@5.1.3 \
    lodash@4.17.21 \
    mathjs@14.7.0 \
    tstl@3.0.0

# Copy execution script (stack size limiter)
COPY node.sh node.sh
