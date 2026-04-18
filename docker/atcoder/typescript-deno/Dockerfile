FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG DENO_VERSION=v2.4.5

WORKDIR /judge

# Install dependencies for Deno installer
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Deno
RUN curl -fsSL https://deno.land/install.sh | sh -s ${DENO_VERSION} -y

ENV DENO_DIR="/root/.cache/deno"
ENV NO_COLOR=1
ENV DENO_NO_UPDATE_CHECK=1
ENV PATH="/root/.deno/bin:${PATH}"

# Setup project and install packages (same as JS Deno + @types/lodash + @types/node)
# Note: TOML does not include @types/node in deno add, but caches it implicitly
# via deno check on test code with /// <reference types="npm:@types/node" />.
# We add it explicitly to ensure it is pre-cached in the image.
RUN echo '{ "imports": {} }' > deno.json \
    && deno add \
        jsr:@std/assert@1.0.14 \
        jsr:@std/async@1.0.14 \
        jsr:@std/bytes@1.0.6 \
        jsr:@std/cache@0.2.0 \
        jsr:@std/cbor@0.1.8 \
        jsr:@std/cli@1.0.22 \
        jsr:@std/collections@1.1.3 \
        jsr:@std/crypto@1.0.5 \
        jsr:@std/csv@1.0.6 \
        jsr:@std/data-structures@1.0.9 \
        jsr:@std/datetime@0.225.5 \
        jsr:@std/dotenv@0.225.5 \
        jsr:@std/encoding@1.0.10 \
        jsr:@std/expect@1.0.17 \
        jsr:@std/fmt@1.0.8 \
        jsr:@std/front-matter@1.0.9 \
        jsr:@std/fs@1.0.19 \
        jsr:@std/html@1.0.4 \
        jsr:@std/http@1.0.20 \
        jsr:@std/ini@0.225.2 \
        jsr:@std/internal@1.0.10 \
        jsr:@std/io@0.225.2 \
        jsr:@std/json@1.0.2 \
        jsr:@std/jsonc@1.0.2 \
        jsr:@std/log@0.224.14 \
        jsr:@std/media-types@1.1.0 \
        jsr:@std/msgpack@1.0.3 \
        jsr:@std/net@1.0.6 \
        jsr:@std/path@1.1.2 \
        jsr:@std/random@0.1.2 \
        jsr:@std/regexp@1.0.1 \
        jsr:@std/semver@1.0.5 \
        jsr:@std/streams@1.0.12 \
        jsr:@std/tar@0.1.8 \
        jsr:@std/testing@1.0.15 \
        jsr:@std/text@1.0.16 \
        jsr:@std/toml@1.0.10 \
        jsr:@std/ulid@1.0.0 \
        jsr:@std/uuid@1.0.9 \
        jsr:@std/webgpu@0.224.8 \
        jsr:@std/yaml@1.0.9 \
        npm:@types/lodash@4.17.20 \
        npm:@types/node@24.2.0 \
        npm:ac-library-js@0.1.1 \
        npm:data-structure-typed@2.0.4 \
        npm:immutable@5.1.3 \
        npm:lodash@4.17.21 \
        npm:mathjs@14.7.0 \
        npm:tstl@3.0.0

# Copy execution script (V8 stack size limiter, runs Main.ts)
COPY deno.sh deno.sh
