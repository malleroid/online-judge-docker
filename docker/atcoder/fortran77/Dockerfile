FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG FPM_VERSION=0.11.0
ARG STDLIB_VERSION=0.7.0

WORKDIR /judge

# Install gfortran and build dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates g++ gfortran gfortran-14 wget git \
        python3 fypp python3-joblib libstdc++-14-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up f77 alternative
RUN update-alternatives --install /usr/bin/f77 f77 /usr/bin/gfortran-14 0 \
    && update-alternatives --set f77 /usr/bin/gfortran-14

# Bootstrap fpm from source instead of downloading the x86_64-only binary.
# This makes the image buildable on both amd64 and arm64.
# Using fpm 0.11.0 (instead of TOML's 0.10.1) because 0.10.1 source
# does not compile with GCC 14. fpm is removed after stdlib is built.
RUN wget -q "https://github.com/fortran-lang/fpm/releases/download/v${FPM_VERSION}/fpm-${FPM_VERSION}.F90" \
        -O /tmp/fpm.F90 \
    && gfortran-14 -g -fbacktrace -O3 /tmp/fpm.F90 -o /tmp/fpm \
    && mkdir -p /root/.local/bin \
    && mv /tmp/fpm /root/.local/bin \
    && rm /tmp/fpm.F90

# Build and install fortran-stdlib
ENV PATH="/root/.local/bin:${PATH}" \
    FPM_FC="gfortran-14" \
    FPM_FFLAGS="-O2 -cpp"

RUN wget -q "https://github.com/fortran-lang/stdlib/archive/refs/tags/v${STDLIB_VERSION}.tar.gz" \
        -O /tmp/stdlib.tar.gz \
    && mkdir /tmp/stdlib \
    && tar -C /tmp/stdlib --strip-components=1 -xf /tmp/stdlib.tar.gz \
    && cd /tmp/stdlib \
    && printf '\n[install]\nlibrary = true\n' >> fpm.toml \
    && python3 config/fypp_deployment.py \
    && fpm build --profile release \
    && fpm test --profile release \
    && fpm install --prefix="/root/.local" --profile release \
    && rm -rf /tmp/stdlib /tmp/stdlib.tar.gz

ENV LD_LIBRARY_PATH="/root/.local/lib"

# Verify installation
RUN printf '      program test_stdlib\n      use, intrinsic :: iso_fortran_env\n      use stdlib_version\n      use stdlib_sorting\n      implicit none\n      integer(int32) :: arr(10) = [10, 2, 1, 5, 7, 8, 3, 9, 6, 4]\n      write(output_unit, '\''(a)'\'') stdlib_version_string\n      call sort(arr)\n      write(error_unit, '\''(*(i0, 1x))'\'') arr(:)\n      if (any(arr(:) /= [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))\n     &     error stop "Something error"\n      end program\n' > Main.f \
    && f77 -L/root/.local/lib -I/root/.local/include -O2 -cpp -ffixed-form Main.f -lstdlib \
    && ./a.out \
    && rm Main.f a.out

# Clean up build-only dependencies (matching TOML cleanup)
RUN rm -f /root/.local/bin/fpm \
    && rm -rf /root/fortran \
    && apt-get purge -y git fypp python3-joblib \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
