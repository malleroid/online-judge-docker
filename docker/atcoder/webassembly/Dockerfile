FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG WAMR_VERSION=2.4.1
ARG WAMR_SHA256=f36650ef534f8bc138ed38385d46cfa5d053fb5696f799a9c783b62418ba726b

# `g++-multilib` and `lib32gcc-13-dev` are amd64-only on Ubuntu 24.04
# (no arm64 packages exist) and the WAMR upstream prebuilt only ships
# x86_64 binaries. The TOML install pulls both 32-bit dev packages
# unconditionally, so this image is amd64 only.
# Build with: docker build --platform linux/amd64
RUN test "${TARGETARCH}" = "amd64" || { echo "WebAssembly image is amd64-only"; exit 1; }

WORKDIR /judge

# TOML packages plus a few that ubuntu:24.04 minimal lacks but the
# AtCoder judge image already provides: `build-essential` (gcc / g++ /
# make / libc6-dev — `g++-multilib` alone does not register the
# unprefixed `g++` and `cc` cmake looks for), `ca-certificates` for
# the HTTPS tarball fetch, `wget` to mirror the TOML's downloader.
# The rest are TOML-verbatim:
#   - `cmake`, `g++-multilib`, `libgcc-13-dev`, `lib32gcc-13-dev`:
#     WAMR build (multilib is required because wamrc emits 32-bit
#     wasm-linear-memory addressing).
#   - `ccache`: TOML keeps it for parity even though Docker's single
#     pass does not benefit from it.
#   - `wabt`: Ubuntu 24.04 universe ships `wabt 1.0.34+dfsg2+~cs1.0.32-1ubuntu2`
#     which exposes `wat2wasm` 1.0.34 — the version the TOML targets.
#   - `llvm`: Ubuntu's `llvm` metapackage on 24.04 pulls LLVM 18,
#     matching WAMR-2.4.1's `release/18.x` expectation. Combined with
#     `-DWAMR_BUILD_WITH_CUSTOM_LLVM=1` below, this avoids the ~30 min
#     in-tree LLVM build the WAMR repo would otherwise trigger.
#   - `llvm-18-dev`: not in the TOML, but Ubuntu's `llvm` only ships
#     the runtime; cmake's `find_package(LLVM REQUIRED CONFIG)` needs
#     `LLVMConfig.cmake` from `llvm-18-dev`. The AtCoder judge image
#     has both packages installed by the wider system; ubuntu:24.04
#     minimal does not.
#   - `git`: TOML installs it (unused by the install script itself but
#     kept for parity).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        g++-multilib \
        git \
        lib32gcc-13-dev \
        libgcc-13-dev \
        llvm \
        llvm-18-dev \
        wabt \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1.  cd /tmp
#   2.  wget -q -O wamr.tar.gz https://.../WAMR-2.4.1.tar.gz
#   3.  mkdir wamr
#   4.  tar -C wamr --strip-components=1 -xf wamr.tar.gz
#   5.  cd wamr
#   6.  cd product-mini/platforms/linux
#   7.  cmake -B build
#   8.  cmake --build build -j$(nproc)
#   9.  cmake --install build                         (iwasm under /usr/local)
#   10. cd ../../..
#   11. cd wamr-compiler
#   12. cmake -B build -DWAMR_BUILD_WITH_CUSTOM_LLVM=1 (uses APT LLVM 18)
#   13. cmake --build build -j$(nproc)
#   14. cmake --install build                         (wamrc under /usr/local)
# `pushd`/`popd` collapse to inline `cd`. `sudo` drops because Docker
# runs as root. sha256 verification is added on the tarball; upstream
# does not publish a checksum file but the GitHub-archive tarball is
# stable per tag.
RUN cd /tmp \
    && wget -q -O wamr.tar.gz \
        "https://github.com/bytecodealliance/wasm-micro-runtime/archive/refs/tags/WAMR-${WAMR_VERSION}.tar.gz" \
    && echo "${WAMR_SHA256}  wamr.tar.gz" | sha256sum -c - \
    && mkdir wamr \
    && tar -C wamr --strip-components=1 -xf wamr.tar.gz \
    && cd wamr/product-mini/platforms/linux \
    && cmake -B build \
    && cmake --build build -j"$(nproc)" \
    && cmake --install build \
    && cd /tmp/wamr/wamr-compiler \
    && cmake -B build -DWAMR_BUILD_WITH_CUSTOM_LLVM=1 \
    && cmake --build build -j"$(nproc)" \
    && cmake --install build \
    && cd / \
    && rm -rf /tmp/wamr /tmp/wamr.tar.gz \
    && ldconfig

# Smoke test: `Main.wat` writes `smoke-ok\n` to stdout via WASI's
# `fd_write`. The TOML compile pipeline is `wat2wasm Main.wat &&
# wamrc -o Main.aot Main.wasm` followed by `iwasm Main.aot`, but
# `wamrc` invokes LLVM ORC against the host CPU and fails under QEMU
# emulation with "LLVM ERROR: 64-bit code requested on a subtarget
# that doesn't support it!" — the emulated x86_64 vCPU reports an
# inconsistent feature set. Running the AOT path as a build-time
# check would falsely fail any Apple-Silicon-hosted
# `docker build --platform linux/amd64`. Instead, the smoke
# exercises `wat2wasm` and `iwasm`'s interpreter mode (no LLVM JIT)
# on the produced `.wasm`, which still asserts the toolchain is
# wired correctly. CI's native amd64 runner exercises the full
# wamrc → iwasm AOT path through actual submissions.
COPY smoke/Main.wat /tmp/smoke/Main.wat
RUN cd /tmp/smoke \
    && wat2wasm Main.wat \
    && out="$(iwasm Main.wasm)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && cd / \
    && rm -rf /tmp/smoke

RUN apt-get purge -y --auto-remove wget \
    && rm -rf /var/lib/apt/lists/*
