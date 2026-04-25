FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TERRA_VERSION=1.2.0
ARG TERRA_BUILD=cc543db
ARG TERRA_SHA256=e897269e57e3a77e1ad773e38ca39db994976488bde0e9e4359ef5c23a521e55

# Terra 1.2.0 only ships an x86_64 LLVM16 prebuilt tarball; the aarch64
# release asset is built against LLVM 11 (different LLVM major), so
# pulling it would diverge from the AtCoder judge env. The TOML pins
# `terra-Linux-x86_64-cc543db-llvm16.tar.xz` explicitly.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# `xz-utils` extracts the .tar.xz upstream archive (not present on
# ubuntu:24.04 minimal); `wget` + `ca-certificates` mirror the TOML's
# fetch step. `build-essential` matches the upstream
# `Dockerfile.ubuntu-prebuilt-test`'s deps so `terralib.includec` can
# resolve C system headers (libc6-dev) at judge time. Terra's runtime
# itself links LLVM statically, so no llvm-dev / libtinfo / libffi /
# libxml2 packages are needed beyond what build-essential pulls in.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1. cd /tmp
#   2. wget https://github.com/terralang/terra/releases/download/release-1.2.0/terra-Linux-x86_64-cc543db-llvm16.tar.xz
#   3. sudo tar -C /usr/local --strip-components=1 -xf terra-Linux-x86_64-cc543db-llvm16.tar.xz
# `--strip-components=1` lays the tarball's `bin/`, `lib/`, `include/`,
# `share/` directly under /usr/local. `sudo` is dropped because Docker
# runs as root. sha256 is verified against an explicit pin since the
# upstream Release does not publish a `digest` field.
RUN cd /tmp \
    && wget -q "https://github.com/terralang/terra/releases/download/release-${TERRA_VERSION}/terra-Linux-x86_64-${TERRA_BUILD}-llvm16.tar.xz" \
    && echo "${TERRA_SHA256}  terra-Linux-x86_64-${TERRA_BUILD}-llvm16.tar.xz" | sha256sum -c - \
    && tar -C /usr/local --strip-components=1 -xf "terra-Linux-x86_64-${TERRA_BUILD}-llvm16.tar.xz" \
    && rm "terra-Linux-x86_64-${TERRA_BUILD}-llvm16.tar.xz"

# Smoke test: reproduce the TOML execute flow (Terra is JIT, no
# separate compile step) with a pure-Lua `print` script. Terra-typed
# functions force LLVM ORC code generation against the host CPU, which
# fails under QEMU emulation with "LLVM ERROR: 64-bit code requested
# on a subtarget that doesn't support it!" because the emulated vCPU
# reports an inconsistent x86_64 feature set. A pure-Lua `print` skips
# the JIT path and still asserts that the binary loads, the
# Lua-fronted runtime initializes, and the standard library is
# reachable — enough to catch a broken tarball extract. CI's native
# amd64 runner exercises the JIT path through real submissions.
RUN set -eu; \
    cd /tmp \
    && echo 'print("smoke-ok")' > Main.t \
    && out="$(terra Main.t 2>&1)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm Main.t

RUN apt-get purge -y --auto-remove wget xz-utils \
    && rm -rf /var/lib/apt/lists/*
