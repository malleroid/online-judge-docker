FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG FREEBASIC_VERSION=1.10.1
ARG FREEBASIC_BOOTSTRAP_SHA256=2fae2c66b435240d4de11bb534843baa188574508a8a5bdaa5020bf729bf0a3e
ARG FREEBASIC_SOURCE_SHA256=4e343f19fab9adfd9a671493f52a941d14af4aec6778e2a3b0da3ec54e50a776

WORKDIR /judge

# TOML install (L2-L3): apt deps. The TOML hardcodes the 12 dev
# libraries fbc links against; `build-essential`, `ca-certificates`,
# and `wget` are added beyond the TOML for ubuntu:24.04 minimal — the
# AtCoder judge image carries them implicitly. The dev packages
# (libgpm/libxext/libxpm/libxrandr/libgl1-mesa/libffi/libncurses/
# libgmp/libgsl/libtre/libglib2.0/libpcre3) stay in the runtime image
# because user submissions can `#include` against any of them.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        wget \
        libgpm-dev \
        libxext-dev \
        libxpm-dev \
        libxrandr-dev \
        libgl1-mesa-dev \
        libffi-dev \
        libncurses-dev \
        libgmp-dev \
        libgsl-dev \
        libtre-dev \
        libglib2.0-dev \
        libpcre3-dev \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L4-L10): two-stage bootstrap. The "source-bootstrap"
# tarball ships pre-translated C sources for `fbc` covering both
# linux-x86_64 and linux-aarch64 (plus other arches we don't target),
# so the host `gcc` can build a stage-1 `fbc` without an existing
# FreeBASIC compiler. `make bootstrap-minimal` is the smaller of the
# two bootstrap targets and matches the TOML literally.
RUN cd /tmp \
    && wget -q -O bootstrap.tar.xz \
        "https://github.com/freebasic/fbc/releases/download/${FREEBASIC_VERSION}/FreeBASIC-${FREEBASIC_VERSION}-source-bootstrap.tar.xz" \
    && echo "${FREEBASIC_BOOTSTRAP_SHA256}  bootstrap.tar.xz" | sha256sum -c - \
    && mkdir bootstrap \
    && tar --strip-components=1 -C bootstrap -xf bootstrap.tar.xz \
    && cd bootstrap \
    && make -j"$(nproc)" bootstrap-minimal

# TOML install (L11-L16): final fbc build using the stage-1 compiler
# from /tmp/bootstrap. The `FBC=...` make variable override is passed
# verbatim from the TOML (single-quoted to keep the `-i` argument
# attached to the same FBC value). `make install` lands `fbc` at
# /usr/local/bin/fbc and the stdlib under /usr/local/lib/freebasic/.
# Cleanup of /tmp/bootstrap and /tmp/fbc-${VERSION} is added beyond
# the TOML to keep the image lean.
RUN cd /tmp \
    && wget -q -O "${FREEBASIC_VERSION}.tar.gz" \
        "https://github.com/freebasic/fbc/archive/refs/tags/${FREEBASIC_VERSION}.tar.gz" \
    && echo "${FREEBASIC_SOURCE_SHA256}  ${FREEBASIC_VERSION}.tar.gz" | sha256sum -c - \
    && tar xf "${FREEBASIC_VERSION}.tar.gz" \
    && cd "fbc-${FREEBASIC_VERSION}" \
    && make -j"$(nproc)" 'FBC=/tmp/bootstrap/bin/fbc -i /tmp/bootstrap/inc' \
    && make install \
    && cd /tmp \
    && rm -rf bootstrap bootstrap.tar.xz "${FREEBASIC_VERSION}.tar.gz" "fbc-${FREEBASIC_VERSION}"

# Smoke test: mirror the TOML compile + execute pipeline. `fbc -O 3
# -arch native Main.bas` produces `Main`, then `./Main` runs it.
RUN printf 'print "Hello, FreeBASIC!"\n' > Main.bas \
    && fbc -O 3 -arch native Main.bas 1>&2 \
    && out="$(./Main)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, FreeBASIC!" \
    && rm -f Main.bas Main
