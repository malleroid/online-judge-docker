FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG C3C_VERSION=0.7.5
ARG C3C_SHA256=7120f11053342a861931459a692039be4cdc8429f336a54f415517193884b29e

# c3c 0.7.5 only ships an x86_64 Linux prebuilt tarball; the v0.7.5
# release exposes Linux assets only as `c3-linux.tar.gz` and
# `c3-ubuntu-22.tar.gz`. There's no aarch64 Linux build, so this image
# is amd64 only.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# `libxml2` is what the TOML installs — the prebuilt tarball bundles
# its own LLVM/lld, but libLLVM dynamically links libxml2 for
# DWARF/CodeView paths. `gcc` and `libc6-dev` are added beyond the
# TOML because `c3c compile` shells out to `cc -o ... -rdynamic
# -pthread ... -ldl` for the final link; the AtCoder judge image
# provides cc/libc-dev implicitly, ubuntu:24.04 minimal does not.
# Both stay in the runtime image. `wget` + `ca-certificates` mirror
# the TOML's fetch step (purged after install).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gcc \
        libc6-dev \
        libxml2 \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1. cd /tmp
#   2. wget https://github.com/c3lang/c3c/releases/download/v0.7.5/c3-linux.tar.gz
#   3. tar -C $HOME -xf c3-linux.tar.gz
# `--strip-components` is not used; the tarball already nests its
# `c3c` binary and stdlib under `c3/`, so extracting under `/opt/`
# yields `/opt/c3/c3c` (`$HOME/c3/c3c` per the TOML's `tar -C $HOME`
# layout). PATH is updated below so the `c3c` invocation in compile
# commands resolves without an absolute path.
RUN cd /tmp \
    && wget -q "https://github.com/c3lang/c3c/releases/download/v${C3C_VERSION}/c3-linux.tar.gz" \
    && echo "${C3C_SHA256}  c3-linux.tar.gz" | sha256sum -c - \
    && tar -C /opt -xf c3-linux.tar.gz \
    && rm c3-linux.tar.gz

ENV PATH=/opt/c3:$PATH

# Smoke test: reproduce the TOML compile/execute flow with the
# `--x86cpu=native` flag dropped. The TOML compile uses `c3c -q
# --ansi=no compile -O5 --x86cpu=native -o a.out Main.c3`, but
# `--x86cpu=native` makes c3c's bundled LLVM probe the host CPU and
# fail under QEMU emulation with "LLVM ERROR: 64-bit code requested
# on a subtarget that doesn't support it!" — the emulated x86_64 vCPU
# reports an inconsistent feature set. Running the native flag as a
# build-time check would falsely fail any Apple-Silicon-hosted
# `docker build --platform linux/amd64`. Stripping the flag still
# exercises the full c3c → LLVM → linker chain and asserts the
# stdlib is reachable; CI's native amd64 runner exercises the
# `--x86cpu=native` path through actual submissions.
RUN set -eu; \
    cd /tmp \
    && { \
        echo 'import std::io;'; \
        echo ''; \
        echo 'fn void main() {'; \
        echo '    io::printn("smoke-ok");'; \
        echo '}'; \
    } > Main.c3 \
    && c3c -q --ansi=no compile -O5 -o a.out Main.c3 \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f Main.c3 a.out

RUN apt-get purge -y --auto-remove wget \
    && rm -rf /var/lib/apt/lists/*
