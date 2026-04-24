FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG BUN_VERSION=1.2.21

WORKDIR /judge

# Install curl for Bun installer
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"

ENV PATH="/root/.bun/bin:${PATH}"
ENV NO_COLOR=true

# Install libraries
RUN bun add --no-cache \
    ac-library-js@0.1.1 \
    data-structure-typed@2.0.4 \
    immutable@5.1.3 \
    lodash@4.17.21 \
    mathjs@14.7.0 \
    tstl@3.0.0
