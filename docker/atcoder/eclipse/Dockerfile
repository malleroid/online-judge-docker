FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG ECLIPSE_VERSION=7.1_13

# eclipseclp.org publishes prebuilt tarballs for both x86_64_linux and
# aarch64_linux but does not ship checksums; sha256 is computed locally
# and pinned per arch.
ARG ECLIPSE_BASIC_AMD64_SHA256=b52e305b01d09be825cb639aeee005f7e9812f0b67dae6bf1d1bd623863bc0a6
ARG IF_OSICLPCBC_AMD64_SHA256=4fa428d8bee712bca0daeee8797535dbb0524f3ee155c9d328b5baf1af1c875b
ARG ECLIPSE_BASIC_ARM64_SHA256=8d14be74eea75cd29351bdea88ab1fe8581d80ad1d72c50e9b4c0ecaefb0b4f7
ARG IF_OSICLPCBC_ARM64_SHA256=e01df2aa38bd9cdf0e7a61575634bd47076832a2a420f2f464dd2a0b58127ab9

ENV HOME=/root

WORKDIR /judge

# `libgmp10`, `libtcl8.6`, and `libtk8.6` are the runtime deps that
# ECLiPSe's prebuilt `eclipse.exe` dynamic-links against. The TOML's
# `# skip tk and java installation` only skips RUNME's Tcl/Tk
# *integration* features (Tcl-bridged GUI), not the libtcl/libtk
# shared libraries themselves — without them the binary fails to
# load with "lib{tcl,tk}8.6.so: cannot open shared object file".
# `wget` / `ca-certificates` mirror the TOML's fetch step (purged
# after).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libgmp10 \
        libtcl8.6 \
        libtk8.6 \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1.  AC2025_ECLIPSE_VERSION=7.1_13                       (Docker ARG)
#   2.  ECLIPSE_DIR="$HOME/.eclipse"
#   3.  mkdir "$ECLIPSE_DIR"
#   4.  cd /tmp
#   5.  wget https://.../x86_64_linux/eclipse_basic.tgz
#   6.  tar xpfz eclipse_basic.tgz -C "$ECLIPSE_DIR"
#   7.  pushd "$ECLIPSE_DIR"
#   8.  yes "" | ./RUNME --no-docs        (auto-accepts every prompt)
#   9.  # skip tk and java installation
#   10. popd
#   11. wget https://.../x86_64_linux/if_osiclpcbc.tgz
#   12. tar xpfz if_osiclpcbc.tgz -C "$ECLIPSE_DIR"
# The TOML hard-codes the `x86_64_linux` URL fragment; we branch on
# TARGETARCH so arm64 hosts pull the matching `aarch64_linux` build
# (eclipseclp.org publishes both). RUNME does not open /dev/tty
# directly, so the TOML's `yes "" | ./RUNME` works under Docker
# without a pseudo-tty wrapper.
RUN set -eu; \
    case "$TARGETARCH" in \
        amd64) ECLIPSE_ARCH=x86_64_linux; \
               BASIC_SHA="${ECLIPSE_BASIC_AMD64_SHA256}"; \
               IF_SHA="${IF_OSICLPCBC_AMD64_SHA256}" ;; \
        arm64) ECLIPSE_ARCH=aarch64_linux; \
               BASIC_SHA="${ECLIPSE_BASIC_ARM64_SHA256}"; \
               IF_SHA="${IF_OSICLPCBC_ARM64_SHA256}" ;; \
        *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    ECLIPSE_DIR="$HOME/.eclipse"; \
    mkdir "$ECLIPSE_DIR" \
    && cd /tmp \
    && wget -q "https://eclipseclp.org/Distribution/Builds/${ECLIPSE_VERSION}/${ECLIPSE_ARCH}/eclipse_basic.tgz" \
    && echo "${BASIC_SHA}  eclipse_basic.tgz" | sha256sum -c - \
    && tar xpfz eclipse_basic.tgz -C "$ECLIPSE_DIR" \
    && cd "$ECLIPSE_DIR" \
    && yes "" | ./RUNME --no-docs \
    && cd /tmp \
    && wget -q "https://eclipseclp.org/Distribution/Builds/${ECLIPSE_VERSION}/${ECLIPSE_ARCH}/if_osiclpcbc.tgz" \
    && echo "${IF_SHA}  if_osiclpcbc.tgz" | sha256sum -c - \
    && tar xpfz if_osiclpcbc.tgz -C "$ECLIPSE_DIR" \
    && rm /tmp/eclipse_basic.tgz /tmp/if_osiclpcbc.tgz \
    && ln -s "$ECLIPSE_DIR/bin/${ECLIPSE_ARCH}/eclipse" /usr/local/bin/eclipse

# Smoke test: reproduce the TOML compile/execute flow end-to-end. The
# TOML pipes `compile('Main.ecl', [output: eco, debug: off])` into
# eclipse to produce `Main.eco`, then runs `eclipse -f Main.eco -e
# main`. The smoke Main.ecl writes `smoke-ok` to stdout via the
# Prolog `main/0` goal.
COPY smoke/Main.ecl /tmp/smoke/Main.ecl
RUN set -eu; \
    cd /tmp/smoke \
    && echo "compile('Main.ecl', [output: eco, debug: off])" | eclipse \
    && out="$(eclipse -f Main.eco -e main)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && cd / \
    && rm -rf /tmp/smoke

RUN apt-get purge -y --auto-remove wget \
    && rm -rf /var/lib/apt/lists/*
