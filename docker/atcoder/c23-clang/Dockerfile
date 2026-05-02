FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG LLVM_VERSION=21.1.0

WORKDIR /judge

# Install runtime / link-time deps. The LLVM prebuilt tarball ships
# clang + lld + compiler-rt + libc++ in one bundle, so build-essential
# is not needed; only the deps that the bundle relies on at runtime
# (libxml2 for ld.lld) and that clang's link step needs (libc6-dev for
# crt*.o + libm, libgcc-14-dev for libgcc / libgcc_s) are required.
# Same dep set as `docker/atcoder/llvm-ir/Dockerfile`, which uses the
# same LLVM 21.1.0 tarball.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        xz-utils \
        libxml2 \
        libc6-dev \
        libgcc-14-dev \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1.  ATCODER_LLVM_VERSION=21.1.0                      (ARG)
#   2.  cd /tmp                                          (-O /tmp/llvm.tar.xz)
#   3.  wget https://.../LLVM-${VERSION}-Linux-X64.tar.xz
#   4.  sudo tar -C /usr --strip-components=1 -xf llvm.tar.xz
#   5.  sudo ldconfig
# `sudo` is dropped (Docker runs as root) and the X64-only URL is
# replaced with a `TARGETARCH` branch so arm64 hosts pull the matching
# `LLVM-${VERSION}-Linux-ARM64.tar.xz`. AtCoder ships only amd64; arm64
# is for local development convenience (same pattern as llvm-ir).
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
        amd64) LLVM_ARCH=X64 ;; \
        arm64) LLVM_ARCH=ARM64 ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && wget -q -O /tmp/llvm.tar.xz \
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-${LLVM_ARCH}.tar.xz" \
    && tar --strip-components=1 -C /usr -xJf /tmp/llvm.tar.xz \
    && ldconfig \
    && rm /tmp/llvm.tar.xz

# Smoke test: mirror the TOML compile + execute flow verbatim. The
# program uses C23-only features (`bool` keyword, `nullptr`) so a
# regression dropping `-std=c23` would fail at compile time. The
# `-rtlib=compiler-rt -fuse-ld=lld` flags exercise the bundle's
# compiler-rt and lld binaries to confirm the tarball unpacked cleanly.
RUN printf '%s\n' \
        '#include <stdio.h>' \
        '#include <math.h>' \
        'int main(void) {' \
        '    bool ok = true;' \
        '    int *p = nullptr;' \
        '    (void)p;' \
        '    printf("%s %g\n", ok ? "Hello, C23!" : "no", sqrt(4.0));' \
        '    return 0;' \
        '}' > Main.c \
    && clang -O2 -march=native -std=c23 -Wall -Wextra -DONLINE_JUDGE -DATCODER -o a.out Main.c -rtlib=compiler-rt -fuse-ld=lld -lm \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = "Hello, C23! 2" ] \
    && rm -f Main.c a.out
