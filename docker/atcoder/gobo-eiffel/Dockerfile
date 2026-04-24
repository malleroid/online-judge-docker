FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GOBO_VERSION=22.01
ARG GOBO_TARBALL_VERSION=2201
ARG GOBO_SRC_SHA256=ed2d82ce3c271e60914a42bde1d1c99446df8902ae1b62fd0e4dca2b99de8068

ENV HOME=/root
ENV GOBO=/root/gobo
ENV PATH=/root/gobo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /judge

# TOML install step, preserved line-for-line (line numbering matches the
# `.toml` original, except where Docker-isms replace `sudo` / `pushd`):
#   1. sudo apt-get update
#   2. sudo apt-get install -y libgc-dev
#   3. pushd $HOME
#   4. wget -q -O /tmp/gobo.tar.gz https://github.com/gobo-eiffel/gobo/...
#   5. tar xf /tmp/gobo.tar.gz
#   6. pushd gobo/bin
#   7. export GOBO=$HOME/gobo   (hoisted to ENV above; still exported by
#      Docker's shell inheritance so install.sh sees the same value)
#   8. ./install.sh --thread=$(nproc) gcc
#   9. popd
#   10. echo 'cflags: -O2 -march=native' >> gobo/tool/gec/config/c/gcc.cfg
#   11. popd
# install.sh bootstraps the vendored `gec{1..9}.c` translations with gcc,
# then self-compiles the rest of the Gobo tool suite (geant/gelex/geyacc/
# gelint/gecop/getest/gedoc/geimage/gepp/gexslt). gcc/libc6-dev/make stay
# in the final image because `gec --gc=boehm main.ecf` invokes gcc at
# judge time to translate the generated C into an ELF binary.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gcc \
        libc6-dev \
        libgc-dev \
        make \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    cd "$HOME" \
    && wget -q -O /tmp/gobo.tar.gz \
        "https://github.com/gobo-eiffel/gobo/releases/download/gobo-${GOBO_VERSION}/gobo${GOBO_TARBALL_VERSION}-src.tar.gz" \
    && echo "${GOBO_SRC_SHA256}  /tmp/gobo.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/gobo.tar.gz \
    && cd "$HOME/gobo/bin" \
    && ./install.sh --thread="$(nproc)" gcc \
    && echo 'cflags: -O2 -march=native' >> "$HOME/gobo/tool/gec/config/c/gcc.cfg" \
    && rm /tmp/gobo.tar.gz

# Smoke test: reproduce the TOML compile/execute flow end-to-end. The
# `main.ecf` is copied verbatim from the TOML (references every
# Gobo-bundled library the judge exposes, including the commented-out
# `thread` library) and paired with a minimal `main.e` printing
# `smoke-ok`. `gec --gc=boehm main.ecf` mirrors the TOML compile
# command; the `<library name="thread" ...>` line is kept as a comment
# exactly as the TOML has it.
COPY smoke/main.ecf smoke/main.e /tmp/smoke/
RUN set -eu; \
    cd /tmp/smoke \
    && gec --gc=boehm main.ecf \
    && out="$(./Main)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && cd / \
    && rm -rf /tmp/smoke

RUN apt-get purge -y --auto-remove wget \
    && rm -rf /var/lib/apt/lists/*
