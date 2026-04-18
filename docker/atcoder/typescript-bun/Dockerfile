FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG BUN_VERSION=1.2.21

WORKDIR /judge

# Install curl, ansifilter for compile error output filtering
RUN apt-get update \
    && apt-get install -y --no-install-recommends ansifilter ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"

ENV PATH="/root/.bun/bin:${PATH}"
ENV NO_COLOR=true

# Install TypeScript, type definitions, and libraries
RUN bun add --no-cache \
    @types/bun@1.2.21 \
    @types/lodash@4.17.20 \
    @types/node@22.18.1 \
    typescript@5.9.2 \
    ac-library-js@0.1.1 \
    data-structure-typed@2.0.4 \
    immutable@5.1.3 \
    lodash@4.17.21 \
    mathjs@14.7.0 \
    tstl@3.0.0
