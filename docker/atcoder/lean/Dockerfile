FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG LEAN_VERSION=v4.22.0

ENV HOME=/root

WORKDIR /judge

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates curl git \
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
# Import all libraries to populate the build cache so users don't hit
# long compilation times on first use (matches TOML test code imports).
RUN cd atcoder \
    && printf 'import Mathlib\nimport Parser\nimport Regex.Regex.Utilities\nimport Regex.Regex.Elab\n\ndef main : IO Unit := IO.println "Hello"\n' > Main.lean \
    && lake exe cache get \
    && lake build \
    && rm .lake/build/bin/atcoder
