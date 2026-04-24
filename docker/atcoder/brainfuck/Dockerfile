FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

# TOML pins commit 14a729d (short); full SHA below
ARG TRITIUM_COMMIT=14a729dd263b6c611b6696e6c06badc35402076a

WORKDIR /judge

# Install build dependencies
# - build-essential: gcc + make to build Tritium from source
# - ca-certificates: HTTPS for git clone
# - git: clone the Brainfuck repository
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

# Build and install Tritium
# Tritium's Makefile auto-detects optional JIT libs (libtcc, libgnulightning, libgmp)
# and auto-disables them if absent. x86-specific DYNASM is auto-disabled on arm64.
# This mirrors AtCoder's minimal install (no optional JIT libs).
RUN git clone https://github.com/rdebath/Brainfuck /tmp/Brainfuck \
    && cd /tmp/Brainfuck \
    && git checkout ${TRITIUM_COMMIT} \
    && cd tritium \
    && make \
    && make install \
    && rm -rf /tmp/Brainfuck

# Smoke test: verify tritium runs TOML's exact execution command
# Classic "print A" program: sets cell to 65 (ASCII 'A') and outputs it
RUN printf '%s' '++++++++[>++++++++<-]>+.' > /tmp/Main.bf \
    && cd /tmp \
    && OUT=$(tritium -b -e Main.bf) \
    && echo "smoke test output: ${OUT}" \
    && [ "${OUT}" = "A" ] \
    && rm /tmp/Main.bf
