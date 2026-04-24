FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG LLVM_VERSION=21.1.0

WORKDIR /judge

# Install runtime dependencies.
# - libxml2 is a runtime dep of ld.lld from the LLVM prebuilt tarball.
# - libc6-dev provides crt*.o, libc.so, libm.so used by clang when linking executables.
# - libgcc-14-dev provides libgcc / libgcc_s that clang links by default.
# The LLVM tarball ships its own clang + lld + libc++; build-essential is not needed.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates wget xz-utils libxml2 libc6-dev libgcc-14-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and install LLVM official prebuilt tarball (multi-arch via TARGETARCH).
# Unpacked into /usr (tar --strip-components=1) to match the TOML install step exactly.
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
        amd64) LLVM_ARCH=X64 ;; \
        arm64) LLVM_ARCH=ARM64 ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && wget -q "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-${LLVM_ARCH}.tar.xz" \
        -O /tmp/llvm.tar.xz \
    && tar --strip-components=1 -C /usr -xJf /tmp/llvm.tar.xz \
    && ldconfig \
    && rm /tmp/llvm.tar.xz

# Smoke test: compile a minimal LLVM IR module using the TOML compile command and run it.
RUN printf '@.str = private unnamed_addr constant [10 x i8] c"smoke-ok\\0A\\00", align 1\ndeclare i32 @printf(ptr, ...)\ndefine i32 @main() {\n  %%1 = call i32 (ptr, ...) @printf(ptr @.str)\n  ret i32 0\n}\n' > Main.ll \
    && clang -O2 -march=native -o a.out Main.ll -fuse-ld=lld -lm \
    && test "$(./a.out)" = "smoke-ok" \
    && rm Main.ll a.out
