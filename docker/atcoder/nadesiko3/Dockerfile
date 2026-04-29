FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG NODE_VERSION=22.19.0
ARG NADESIKO3_VERSION=3.7.8

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

# Install nadesiko3
RUN npm install -g nadesiko3@${NADESIKO3_VERSION}

# Copy execution script (stack size limiter, mirrors the TOML's heredoc verbatim
# including the trailing backslash on the last `node` argument).
# Note: nadesiko3's node.sh does NOT pass `ONLINE_JUDGE` / `ATCODER` to node,
# unlike the JavaScript (Node.js) entry. The TOML keeps these two scripts
# distinct, so the file is duplicated rather than shared.
COPY node.sh node.sh

# Smoke test mirrors the TOML's terminal install steps (compile + run + cleanup).
RUN echo '「こんにちは」と表示' > Main.nako3 \
    && cnako3 -c Main.nako3 \
    && out="$(sh node.sh 2097152 Main.mjs)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "こんにちは" \
    && rm -f Main.mjs Main.nako3
