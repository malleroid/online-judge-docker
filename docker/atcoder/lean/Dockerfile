FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG LEAN_VERSION=v4.22.0

ENV HOME=/root

WORKDIR /judge

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

# Install elan and Lean
RUN curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/elan-init.sh \
    && chmod +x /tmp/elan-init.sh \
    && /tmp/elan-init.sh -y --default-toolchain leanprover/lean4:${LEAN_VERSION} \
    && rm /tmp/elan-init.sh

ENV PATH="${HOME}/.elan/bin:${PATH}"

# Create lake project
RUN lake new atcoder exe

# Add library dependencies to lakefile.toml
RUN cd atcoder \
    && printf '\n[[require]]\nname = "Regex"\ngit = "https://github.com/pandaman64/lean-regex"\nrev = "%s"\nsubDir = "regex"\n\n[[require]]\nname = "mathlib"\nscope = "leanprover-community"\nrev = "%s"\n\n[[require]]\nname = "Parser"\nscope = "fgdorais"\nrev = "617f4fa"\n' "${LEAN_VERSION}" "${LEAN_VERSION}" >> lakefile.toml

# Fetch mathlib prebuilt cache and build project
RUN cd atcoder \
    && echo 'def main : IO Unit := IO.println "Hello"' > Main.lean \
    && lake exe cache get \
    && lake build \
    && rm .lake/build/bin/atcoder
