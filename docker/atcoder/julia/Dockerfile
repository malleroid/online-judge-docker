FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG JULIA_VERSION=1.11.6

WORKDIR /judge

# Install curl for juliaup installer
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Install Julia via juliaup
RUN curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel ${JULIA_VERSION}

ENV PATH="/root/.juliaup/bin:${PATH}"

# Install packages with pinned versions
RUN julia -e 'using Pkg; Pkg.update(); for (name, version) in map(p -> String.(split(p, "@")), ARGS) Pkg.add(name=name, version=version); end' \
    Combinatorics@1.0.3 \
    DataStructures@0.18.22 \
    DelimitedFiles@1.9.1 \
    Distributions@0.25.120 \
    InvertedIndices@1.3.1 \
    IterTools@1.10.0 \
    OffsetArrays@1.17.0 \
    PrecompileTools@1.2.1 \
    Primes@0.5.7 \
    StaticArrays@1.9.14

# Precompile all packages
RUN julia -e "using Combinatorics, DataStructures, DelimitedFiles, Distributions, InvertedIndices, IterTools, OffsetArrays, PrecompileTools, Primes, StaticArrays"

# Disable juliaup auto-updates
RUN juliaup config backgroundselfupdateinterval 0 \
    && juliaup config startupselfupdateinterval 0 \
    && juliaup config versionsdbupdateinterval 0
