FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG NODE_VERSION=22.19.0

WORKDIR /judge

# Install Leiningen and dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates leiningen wget xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN NODE_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") \
    && wget -q -O /tmp/node.tar.xz \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
    && tar -C /usr/local --strip-components=1 -xf /tmp/node.tar.xz \
        --wildcards '*/bin' '*/share' '*/lib' '*/include' \
    && rm /tmp/node.tar.xz

ENV NODE_PATH=/usr/local/lib/node_modules

# Create ClojureScript project
RUN lein new figwheel-node main

# Install npm libraries
RUN cd main \
    && npm install ac-library-js@0.1.1 data-structure-typed@2.0.4 source-map-support

# Update project.clj for ClojureScript 1.12.42
RUN cd main \
    && sed -i \
        's@org\.clojure/clojure ".*"@org.clojure/clojure "1.12.2"@; s@org\.clojure/clojurescript ".*"@org.clojure/clojurescript "1.12.42"@; s@:target :nodejs@:target :nodejs\n                :source-map "server.js.map"\n                :npm-deps {:data-structure-typed "*" :ac-library-js "*"}@g' \
        project.clj

# Pre-build with dummy source
RUN cd main \
    && printf '(ns main.core)\n(js/console.log "Hello")\n' > src/main/core.cljs \
    && lein cljsbuild once prod \
    && rm server.js

# Copy execution wrapper script
COPY node.sh node.sh
