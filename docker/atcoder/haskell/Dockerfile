FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG GHC_VERSION=9.8.4
ARG CABAL_VERSION=3.14.2.0

ENV HOME=/root

WORKDIR /judge

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl \
        libffi-dev libffi8ubuntu1 libgmp-dev libgmp10 \
        libncurses-dev libncurses6 libtinfo6 llvm-15 \
    && rm -rf /var/lib/apt/lists/*

# Install hmatrix native dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libatlas-base-dev libglpk-dev libgsl0-dev liblapack-dev \
    && rm -rf /var/lib/apt/lists/*

# Install GHCup, GHC, and Cabal
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org \
        | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh \
    && . ${HOME}/.ghcup/env \
    && ghcup install cabal ${CABAL_VERSION} \
    && ghcup set cabal ${CABAL_VERSION} \
    && ghcup install ghc ${GHC_VERSION} \
    && ghcup set ghc ${GHC_VERSION}

ENV PATH="${HOME}/.ghcup/bin:${HOME}/.cabal/bin:${PATH}"

# Set up Cabal project
COPY submission/submission.cabal submission/submission.cabal
COPY submission/cabal.project submission/cabal.project
COPY submission/cabal.project.freeze submission/cabal.project.freeze

# Pre-build all dependencies
RUN mkdir -p submission/app \
    && echo 'main = return () :: IO ()' > submission/app/Main.hs \
    && cd submission \
    && cabal v2-update \
    && cabal v2-configure --flags="+atcoder" \
    && cabal v2-build --only-dependencies \
    && rm app/Main.hs
