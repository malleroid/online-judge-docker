FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG VERYLUP_VERSION=0.1.7
ARG VERYL_VERSION=0.16.4

ARG VERYLUP_AMD64_SHA256=d8f31de7e0ece97290684022783ac8441a63a3f33a673f6f6359d774f4f55461
ARG VERYLUP_ARM64_SHA256=c7e15737a67d131881384d3bcc17e5e9fee2cb5400958ad61801c4794c014408

ENV HOME=/root
ENV PATH=/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /judge

# `verilator` and `git` come straight from the TOML. `g++` / `libc6-dev`
# / `make` round out the C++ toolchain that `verilator --binary` invokes
# when turning the generated SystemVerilog into a native simulation
# binary; the AtCoder judge image already has them, ubuntu:24.04 does
# not. `wget` / `unzip` / `ca-certificates` are needed to fetch and
# extract the verylup zip.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        g++ \
        git \
        libc6-dev \
        make \
        unzip \
        verilator \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1. AC_VERYL_VERSION=0.16.4              (Docker ARG)
#   2. sudo apt-get update                  (above)
#   3. sudo apt-get install -y verilator git (above)
#   4. cd /tmp
#   5. wget https://.../verylup-x86_64-linux.zip
#   6. mkdir $HOME/bin
#   7. unzip verylup-x86_64-linux.zip -d $HOME/bin
#   8. (popd)
#   9. export PATH=$HOME/bin:$PATH          (ENV PATH above)
#   10. verylup setup                       (writes ~/.config/verylup
#                                            and creates veryl / veryl-ls
#                                            hardlinks in $HOME/bin)
#   11. verylup install 0.16.4
#   12. verylup uninstall latest
#   13. veryl new main
# The TOML hardcodes the x86_64 verylup asset; we branch on TARGETARCH
# so arm64 picks the aarch64 build (verylup ships pre-built binaries
# for both, and `verylup install 0.16.4` likewise pulls the matching
# `veryl-{arch}-linux.zip`). sha256 for each arch is pinned via ARG.
RUN set -eu; \
    case "$TARGETARCH" in \
        amd64) verylup_arch=x86_64; verylup_sha256="${VERYLUP_AMD64_SHA256}" ;; \
        arm64) verylup_arch=aarch64; verylup_sha256="${VERYLUP_ARM64_SHA256}" ;; \
        *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    cd /tmp \
    && wget -q -O verylup.zip \
        "https://github.com/veryl-lang/verylup/releases/download/v${VERYLUP_VERSION}/verylup-${verylup_arch}-linux.zip" \
    && echo "${verylup_sha256}  verylup.zip" | sha256sum -c - \
    && mkdir -p "$HOME/bin" \
    && unzip -q verylup.zip -d "$HOME/bin" \
    && rm verylup.zip \
    && verylup setup \
    && verylup install "${VERYL_VERSION}" \
    && verylup uninstall latest \
    && cd /judge \
    && veryl new main

# Smoke test: reproduce the TOML compile/execute flow end-to-end on a
# tiny Veryl module that prints `smoke-ok` via the `$display` syscall
# (transpiled straight into SystemVerilog). `veryl build` generates the
# SV sources plus `main.f` (the verilator command file), then verilator
# compiles them with the TOML's exact `-CFLAGS "-O2 -march=native"
# --binary -f main.f` invocation. `./obj_dir/Vmain </dev/null` runs the
# simulation; the binary always emits Verilator banners around the user
# `$display`, so the assertion uses `grep -qF` against the marker.
RUN set -eu; \
    cd /judge/main \
    && { \
        echo 'module Main {'; \
        echo '    initial {'; \
        echo '        $display("smoke-ok");'; \
        echo '        $finish();'; \
        echo '    }'; \
        echo '}'; \
    } > src/main.veryl \
    && veryl build --quiet \
    && verilator -CFLAGS "-O2 -march=native" --binary -f main.f \
    && out="$(./obj_dir/Vmain </dev/null)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qF "smoke-ok"

RUN apt-get purge -y --auto-remove unzip wget \
    && rm -rf /var/lib/apt/lists/*
