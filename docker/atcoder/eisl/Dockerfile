FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG EISL_VERSION=5.43
ARG EISL_SHA256=02c822fd397f7d6505844fdad5ff77455371bc2e7387de9fbb25c4c8177dff55

WORKDIR /judge

# gcc and libc6-dev are retained at runtime because `eisl -cr` invokes
# `cc` to compile the generated C source into an object file.
# make / curl / libncurses-dev are only needed to build eisl itself.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        libc6-dev \
        libncurses-dev \
        make \
    && rm -rf /var/lib/apt/lists/*

# Build and install Easy-ISLisp.
# SHAREDIR is embedded into the binary at build time, so we explicitly
# pass it to `make all`. We do NOT run `make install` because upstream's
# install target pulls in more files than the AtCoder judge environment
# installs; instead we mirror the TOML's curated subset literally.
RUN curl -fsSL -o /tmp/eisl.tar.gz \
        "https://github.com/sasagawa888/eisl/archive/refs/tags/v${EISL_VERSION}.tar.gz" \
    && echo "${EISL_SHA256}  /tmp/eisl.tar.gz" | sha256sum -c - \
    && mkdir /tmp/eisl \
    && tar -C /tmp/eisl --strip-components=1 -xf /tmp/eisl.tar.gz \
    && cd /tmp/eisl \
    && make all SHAREDIR=/usr/local/share/eisl PREFIX=/usr/local \
    && install -m 755 eisl /usr/local/bin \
    && mkdir -p -m 755 /usr/local/share/eisl \
    && mkdir -p -m 755 /usr/local/share/eisl/library \
    && install -m 644 library/compiler.lsp /usr/local/share/eisl/library \
    && install -m 644 fast.h ffi.h /usr/local/share/eisl \
    && install -m 644 library/bit.o /usr/local/share/eisl/library \
    && install -m 644 library/string.lsp /usr/local/share/eisl/library \
    && install -m 644 library/elixir.lsp /usr/local/share/eisl/library \
    && install -m 644 library/hash.lsp /usr/local/share/eisl/library \
    && install -m 644 library/queue.lsp /usr/local/share/eisl/library \
    && install -m 644 library/seq.lsp /usr/local/share/eisl/library \
    && install -m 644 library/list.lsp /usr/local/share/eisl/library \
    && install -m 644 library/cxr.lsp /usr/local/share/eisl/library \
    && install -m 644 library/lazy.lsp /usr/local/share/eisl/library \
    && install -m 644 library/macro.lsp /usr/local/share/eisl/library \
    && install -m 644 library/rational.lsp /usr/local/share/eisl/library \
    && rm -rf /tmp/eisl /tmp/eisl.tar.gz

# Smoke test: mirrors the TOML's compile + execute flow.
RUN printf '(format (standard-output) "smoke-ok~%%")\n' > main.lsp \
    && (echo '(compile-file "main.lsp")' | eisl -cr) > output \
    && test -f main.o \
    && eisl -s main.o | grep -q smoke-ok \
    && rm -f main.lsp main.o output

# Purge build-only dependencies. gcc / libc6-dev stay because they are
# required at runtime for `compile-file` (eisl -cr emits C and invokes cc).
RUN apt-get purge -y curl libncurses-dev make \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
