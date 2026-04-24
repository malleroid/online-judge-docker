FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG FPM_VERSION=0.11.0
ARG STDLIB_VERSION=0.7.0
ARG LLVM_VERSION=20.1.7

WORKDIR /judge

# Install build dependencies.
# - build-essential stays in the final image: flang-new needs ld / -lgcc_s at runtime for linking.
# - gfortran-14 is only needed to bootstrap fpm; purged in the cleanup step below.
# - fypp / python3-joblib are only needed for stdlib's fypp_deployment; purged in cleanup.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates wget git xz-utils build-essential \
        gfortran-14 python3 fypp python3-joblib \
    && rm -rf /var/lib/apt/lists/*

# Download and install LLVM/Flang official prebuilt tarball (multi-arch via TARGETARCH).
# The tarball is installed as-is under /root/.local to exactly reproduce the judge environment
# (TOML uses rsync to copy the tree; we use tar --strip-components=1 to avoid rsync dependency).
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
        amd64) LLVM_ARCH=X64 ;; \
        arm64) LLVM_ARCH=ARM64 ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && wget -q "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-${LLVM_ARCH}.tar.xz" \
        -O /tmp/llvm.tar.xz \
    && mkdir -p /root/.local \
    && tar --strip-components=1 -C /root/.local -xJf /tmp/llvm.tar.xz \
    && rm /tmp/llvm.tar.xz

# Bootstrap fpm from source using gfortran-14.
# flang-new cannot compile fpm (fpm uses GCC-specific extensions that flang-new rejects),
# and fpm 0.10.1 source does not compile with GCC 14; hence we use fpm 0.11.0.
# fpm is removed after stdlib is built (see cleanup below).
RUN wget -q "https://github.com/fortran-lang/fpm/releases/download/v${FPM_VERSION}/fpm-${FPM_VERSION}.F90" \
        -O /tmp/fpm.F90 \
    && gfortran-14 -g -fbacktrace -O3 /tmp/fpm.F90 -o /tmp/fpm \
    && mkdir -p /root/.local/bin \
    && mv /tmp/fpm /root/.local/bin \
    && rm /tmp/fpm.F90

# Put /root/.local/bin (flang-new, fpm) on PATH and configure fpm to use flang-new for stdlib.
ENV PATH="/root/.local/bin:${PATH}" \
    FPM_FC="flang-new" \
    FPM_FFLAGS="-O2 -cpp -std=f2018"

# Build and install fortran-stdlib with the patches required for flang-new.
# - The two stdlib_math* sed patches work around flang-new's stricter handling of array sizing.
# - The stdlib_specialfunctions_gamma patch falls back from real128 (unsupported by flang-new
#   at this version) to real64.
# - example/ is removed to avoid compiling unused sample code.
# - `fpm test` is skipped because stdlib's tests assume real128, which is still downgraded to
#   real64 in the patched sources (matches TOML behavior).
RUN wget -q "https://github.com/fortran-lang/stdlib/archive/refs/tags/v${STDLIB_VERSION}.tar.gz" \
        -O /tmp/stdlib.tar.gz \
    && mkdir /tmp/stdlib \
    && tar -C /tmp/stdlib --strip-components=1 -xf /tmp/stdlib.tar.gz \
    && cd /tmp/stdlib \
    && printf '\n[install]\nlibrary = true\n' >> fpm.toml \
    && sed -i -e 's/res(max(n, 0))/res(n)/' src/stdlib_math.fypp \
    && sed -i -e 's/res(max(n, 0))/res(n)/' src/stdlib_math_linspace.fypp \
    && sed -i -e 's/qp => real128/qp => real64/' src/stdlib_specialfunctions_gamma.fypp \
    && rm -rf example/ \
    && python3 config/fypp_deployment.py \
    && fpm build --profile release \
    && fpm install --prefix="/root/.local" --profile release \
    && rm -rf /tmp/stdlib /tmp/stdlib.tar.gz

ENV LD_LIBRARY_PATH="/root/.local/lib"

# Install ac-library-fortran (HEAD — matches TOML literally, keeps .git)
RUN git clone https://github.com/ue1221/ac-library-fortran.git /judge/acl

# Verify installation using both stdlib and ac-library-fortran (TOML's exact Main.f90 test)
RUN printf 'include "acl/atcoder/union_find.f08"\nprogram test_stdlib\n  use, intrinsic :: iso_fortran_env\n  use stdlib_version\n  use stdlib_sorting\n  use mod_union_find\n  implicit none\n  integer(int32) :: arr(10) = [10, 2, 1, 5, 7, 8, 3, 9, 6, 4]\n  type(union_find) :: uf\n  write(output_unit, '\''(a)'\'') stdlib_version_string\n  call sort(arr)\n  write(error_unit, '\''(*(i0, 1x))'\'') arr(:)\n  if (any(arr(:) /= [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])) &\n      & error stop "Something error"\n  uf = newuf(10)\n  call unite(uf, 1, 2)\n  write(error_unit, '\''(*(L, 1x))'\'') same(uf, 1, 2), same(uf, 1, 3)\nend program\n' > Main.f90 \
    && flang-new -L/root/.local/lib -I/root/.local/include -O2 -cpp -std=f2018 Main.f90 -lstdlib \
    && ./a.out \
    && rm Main.f90 a.out mod_union_find.mod

# Clean up build-only dependencies (matching TOML cleanup)
RUN rm -f /root/.local/bin/fpm \
    && apt-get purge -y gfortran-14 git fypp python3-joblib \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
