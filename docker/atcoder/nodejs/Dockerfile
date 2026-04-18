FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG NODE_VERSION=22.19.0

WORKDIR /judge

# Install wget and xz for downloading Node.js
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget xz-utils \
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

# Install libraries
RUN npm install -g \
    ac-library-js@0.1.1 \
    data-structure-typed@2.0.4 \
    immutable@5.1.3 \
    lodash@4.17.21 \
    mathjs@14.7.0 \
    tstl@3.0.0

# Copy execution script (stack size limiter)
COPY node.sh node.sh
