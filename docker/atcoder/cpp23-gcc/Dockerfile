FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GCC_VERSION=15.2.0
ARG ABSEIL_VERSION=20250512.1
ARG AC_LIBRARY_VERSION=1.6
ARG BOOST_VERSION=1.88.0
ARG EIGEN_APT_VERSION=3.4.0-4
ARG GMP_APT_VERSION=2:6.3.0+dfsg-2ubuntu6.1
ARG IMMER_VERSION=0.8.1
ARG LIBTORCH_VERSION=2.8.0
ARG LIGHTGBM_VERSION=4.6.0
ARG ORTOOLS_VERSION=9.14
ARG RANGE_V3_VERSION=0.12.0
ARG UNORDERED_DENSE_VERSION=4.5.0
ARG Z3_VERSION=4.15.2

# AtCoder's judge runs amd64 only. The TOML pulls libtorch's
# `libtorch-shared-with-deps-2.8.0+cpu.zip`, whose precompiled .so
# files only ship for x86_64. Building libtorch for arm64 from source
# would balloon the build time; outside the scope of "reproduce the
# judge env". Build with:
#   docker build --platform linux/amd64

ENV AC_INSTALL_DIR=/opt/atcoder/gcc
ENV PATH=/opt/atcoder/gcc/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# The TOML's install script uses bash-only parameter expansions
# (`${BOOST_VERSION//./_}`, `${CMAKE_PATH//'/'/'\/'}`) that fail under
# dash. Switching the Dockerfile shell to bash mirrors the TOML's
# original interpreter and keeps the substitutions byte-aligned.
SHELL ["/bin/bash", "-c"]

WORKDIR /judge

# TOML install (L78-L86): set up /etc/atcoder/install_dir.txt + apt
# build tools. The TOML's `apt-get install -y git cmake lld
# ninja-build pigz pbzip2` is preserved verbatim; `wget xz-utils
# unzip ca-certificates build-essential bzip2 binutils libc6-dev
# python3` are added beyond the TOML for the bare ubuntu:24.04 image
# (the AtCoder judge image carries them implicitly). `build-essential`
# provides the bootstrap `gcc-13/g++-13` needed to compile GCC 15.2.0
# from source. `binutils` and `libc6-dev` are explicitly named (not
# just pulled in transitively by `build-essential`) so the finalize
# step's `apt-get purge --auto-remove` does not strip them — the GCC
# source build does not ship its own `as`/`ld` or system `crt*.o` /
# `-lm`, so user submissions need the system binutils + libc6-dev at
# runtime. `python3` is required by Z3's cmake configure step (Z3's
# generator runs as a `find_package(Python3)` requirement).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        xz-utils \
        unzip \
        bzip2 \
        build-essential \
        binutils \
        libc6-dev \
        python3 \
        git \
        cmake \
        lld \
        ninja-build \
        pigz \
        pbzip2 \
    && mkdir -p /etc/atcoder \
    && echo "${AC_INSTALL_DIR}" > /etc/atcoder/install_dir.txt \
    && mkdir -p "${AC_INSTALL_DIR}/include" "${AC_INSTALL_DIR}/lib"

# TOML install (L102-L135): GCC 15.2.0 source build. `--disable-bootstrap`
# halves wall-clock by skipping the stage2/stage3 self-rebuilds; AtCoder
# does the same. `contrib/download_prerequisites` fetches GMP / MPFR /
# MPC / ISL into the source tree so the configure step is hermetic
# beyond the apt build chain. `--disable-libada/libgm2` prunes
# unsupported frontends; `--enable-languages=c++` keeps only what we
# need (cLay/Jule will reuse this template; gccgo will swap in `c,c++,go`).
# This single layer dominates total build time (~25-35 min on
# `ubuntu-latest`).
RUN cd /tmp \
    && wget -q -O gcc.tar.gz \
        "http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz" \
    && mkdir -p gcc \
    && tar -I pigz -xf gcc.tar.gz -C gcc --strip-components=1 \
    && cd gcc \
    && ./contrib/download_prerequisites \
    && mkdir build \
    && cd build \
    && ../configure \
        --prefix="${AC_INSTALL_DIR}" \
        --enable-languages=c++ \
        --disable-bootstrap \
        --disable-multilib \
        --disable-libsanitizer \
        --disable-checking \
        --disable-nls \
        --disable-gcov \
        --disable-libada \
        --disable-libgm2 \
    && make -j"$(nproc)" \
    && make install \
    && ln -sf "${AC_INSTALL_DIR}/bin/gcc" /usr/local/bin/gcc \
    && ln -sf "${AC_INSTALL_DIR}/bin/g++" /usr/local/bin/g++ \
    && cd / \
    && rm -rf /tmp/gcc /tmp/gcc.tar.gz

# Shared cxxflags for library builds (TOML's `INTERNALL_BUILD_FLAGS`,
# verbatim minus `::install_dir::` substitution). The trailing `-w`
# suppresses warnings during library compile so the build noise stays
# manageable. Unlike the clang variant, GCC needs neither `-stdlib=
# libc++` nor `-rtlib=compiler-rt` nor `-fuse-ld=lld` here — the system
# linker and libstdc++ are correct out-of-the-box.
ENV INTERNALL_BUILD_FLAGS="-std=gnu++23 -w -L/opt/atcoder/gcc/lib64 -Wl,-R/opt/atcoder/gcc/lib64"

# TOML install (L191-L216): abseil 20250512.1 with `-fPIC` so or-tools
# can link it statically. `ABSL_USE_SYSTEM_INCLUDES=ON` stops abseil's
# headers from appearing under `include/absl/...` SYSTEM-include flag
# the way it does for downstreams; `ABSL_PROPAGATE_CXX_STD=ON` makes
# the consuming target inherit `-std=gnu++23`.
RUN cd /tmp \
    && wget -q -O abseil.tar.gz \
        "https://github.com/abseil/abseil-cpp/releases/download/${ABSEIL_VERSION}/abseil-cpp-${ABSEIL_VERSION}.tar.gz" \
    && mkdir -p abseil \
    && tar -I pigz -xf abseil.tar.gz -C abseil --strip-components=1 \
    && cd abseil \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DABSL_ENABLE_INSTALL=ON \
        -DABSL_PROPAGATE_CXX_STD=ON \
        -DABSL_USE_SYSTEM_INCLUDES=ON \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        -DCMAKE_CXX_FLAGS="-fPIC ${INTERNALL_BUILD_FLAGS}" \
        .. \
    && cmake --build . --target install \
    && cd / \
    && rm -rf /tmp/abseil /tmp/abseil.tar.gz

# TOML install (L217-L226): ac-library 1.6 is header-only — copy the
# `atcoder/` headers tree directly into the install prefix.
RUN cd /tmp \
    && wget -q -O ac-library.tar.gz \
        "https://github.com/atcoder/ac-library/archive/refs/tags/v${AC_LIBRARY_VERSION}.tar.gz" \
    && mkdir -p ac-library \
    && tar -I pigz -xf ac-library.tar.gz -C ac-library --strip-components=1 \
    && cp -rf ac-library/atcoder "${AC_INSTALL_DIR}/include" \
    && rm -rf /tmp/ac-library /tmp/ac-library.tar.gz

# TOML install (L227-L264): boost 1.88.0 with bootstrap.sh + b2.
# `link=static threading=single` matches the TOML;
# `mpi/graph_parallel/python` are excluded verbatim. The clang variant
# adds `--target=x86_64-unknown-linux-gnu` to b2's cxxflags; the GCC
# variant intentionally does not (TOML's `BOOST_BUILD_FLAGS` array is
# only populated under `AC_VARIANT==clang`).
RUN cd /tmp \
    && wget -q -O boost.tar.bz2 \
        "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.bz2" \
    && mkdir -p boost \
    && tar -I pbzip2 -xf boost.tar.bz2 -C boost --strip-components=1 \
    && cd boost \
    && echo "using gcc : : g++ ;" > user-config.jam \
    && ./bootstrap.sh \
        --with-toolset=gcc \
        --without-libraries=mpi,graph_parallel,python \
        --prefix="${AC_INSTALL_DIR}" \
    && ./b2 \
        toolset=gcc \
        link=static \
        threading=single \
        variant=release \
        cflags="-w" \
        cxxflags="${INTERNALL_BUILD_FLAGS}" \
        --user-config=./user-config.jam \
        -j"$(nproc)" -d0 \
        install \
    && cd / \
    && rm -rf /tmp/boost /tmp/boost.tar.bz2

# TOML install (L265-L286): Eigen3 via apt copy hack. The TOML pins
# the apt package version, copies the headers and CMake config into
# `$AC_INSTALL_DIR`, rewrites the include path inside the CMake config,
# then removes the apt package so only the relocated copy remains.
RUN apt-get install -y --no-install-recommends "libeigen3-dev=${EIGEN_APT_VERSION}" \
    && mkdir -p "${AC_INSTALL_DIR}/cmake" \
    && cp -Trf /usr/include/eigen3 "${AC_INSTALL_DIR}/include" \
    && cp -f /usr/share/eigen3/cmake/Eigen3Targets.cmake \
        /usr/share/eigen3/cmake/Eigen3Config.cmake \
        "${AC_INSTALL_DIR}/cmake" \
    && CMAKE_PATH="${AC_INSTALL_DIR}/include" \
    && CMAKE_PATH="${CMAKE_PATH#/opt/}" \
    && sed -i "s|include/eigen3|${CMAKE_PATH//'/'/'\/'}|g" \
        "${AC_INSTALL_DIR}/cmake/Eigen3Targets.cmake" \
    && apt-get remove -y libeigen3-dev

# TOML install (L287-L292): GMP 6.3.0 via apt direct (no relocate).
RUN apt-get install -y --no-install-recommends "libgmp3-dev=${GMP_APT_VERSION}"

# TOML install (L293-L303): immer 0.8.1 is header-only.
RUN cd /tmp \
    && wget -q -O immer.tar.gz \
        "https://github.com/arximboldi/immer/archive/refs/tags/v${IMMER_VERSION}.tar.gz" \
    && mkdir -p immer \
    && tar -I pigz -xf immer.tar.gz -C immer --strip-components=1 \
    && cp -Trf immer/immer "${AC_INSTALL_DIR}/include/immer" \
    && rm -rf /tmp/immer /tmp/immer.tar.gz

# TOML install (L304-L318): LibTorch 2.8.0 CPU. Unlike the clang
# variant (which short-circuits on `AC_VARIANT==clang`), the GCC
# variant downloads the precompiled C++ distribution and copies its
# headers + libs into the install prefix. The bundled
# `libprotobuf*.a / libprotoc.a` archives are removed before copy
# because or-tools rebuilds protobuf statically downstream and the
# duplicate static archives would collide at link time.
RUN cd /tmp \
    && wget -q -O libtorch.zip \
        "https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-${LIBTORCH_VERSION}%2Bcpu.zip" \
    && unzip -q libtorch.zip \
    && rm -f \
        ./libtorch/lib/libprotobuf.a \
        ./libtorch/lib/libprotobuf-lite.a \
        ./libtorch/lib/libprotoc.a \
    && cp -Trf ./libtorch/include "${AC_INSTALL_DIR}/include" \
    && cp -Trf ./libtorch/lib     "${AC_INSTALL_DIR}/lib" \
    && rm -rf /tmp/libtorch /tmp/libtorch.zip

# TOML install (L319-L340): LightGBM 4.6.0 with `BUILD_STATIC_LIB=ON`,
# `USE_HOMEBREW_FALLBACK=OFF`. `lightgbm` (CLI dir) and
# `external_libs/eigen` are removed before build to force the system
# Eigen we just installed to be picked up. GCC's libgomp is
# auto-detected so no explicit `OpenMP_*` overrides are needed (unlike
# the clang variant which has to point at the source-built `libomp.so`).
RUN cd /tmp \
    && wget -q -O lightgbm.tar.gz \
        "https://github.com/microsoft/LightGBM/releases/download/v${LIGHTGBM_VERSION}/lightgbm-${LIGHTGBM_VERSION}.tar.gz" \
    && mkdir -p lightgbm \
    && tar -I pigz -xf lightgbm.tar.gz -C lightgbm --strip-components=1 \
    && cd lightgbm \
    && rm -rf lightgbm external_libs/eigen \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DBUILD_CLI=OFF \
        -DBUILD_STATIC_LIB=ON \
        -DUSE_HOMEBREW_FALLBACK=OFF \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        -DCMAKE_CXX_FLAGS="${INTERNALL_BUILD_FLAGS} -I${AC_INSTALL_DIR}/include -fopenmp" \
        .. \
    && cmake --build . --target install \
    && cd / \
    && rm -rf /tmp/lightgbm /tmp/lightgbm.tar.gz

# TOML install (L341-L374): OR-Tools 9.14 — the heaviest single build.
# All major solver backends are enabled (Cbc/Cgl/Clp/CoinUtils/Osi
# from COIN-OR, plus GLPK, HIGHS, SCIP). `BUILD_SHARED_LIBS=OFF` keeps
# everything as static archives that the user submission can link in
# one shot.
RUN cd /tmp \
    && wget -q -O or-tools.tar.gz \
        "https://github.com/google/or-tools/archive/refs/tags/v${ORTOOLS_VERSION}.tar.gz" \
    && mkdir -p or-tools \
    && tar -I pigz -xf or-tools.tar.gz -C or-tools --strip-components=1 \
    && cd or-tools \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DBUILD_CXX=ON \
        -DBUILD_BZip2=ON -DBUILD_ZLIB=ON -DBUILD_Protobuf=ON -DBUILD_re2=ON \
        -DUSE_COINOR=ON -DBUILD_CoinUtils=ON -DBUILD_Osi=ON -DBUILD_Clp=ON -DBUILD_Cgl=ON -DBUILD_Cbc=ON \
        -DUSE_GLPK=ON -DBUILD_GLPK=ON \
        -DUSE_HIGHS=ON -DBUILD_HIGHS=ON \
        -DUSE_SCIP=ON -DBUILD_SCIP=ON -DBUILD_soplex=ON -DBUILD_Boost=ON \
        -DBUILD_SAMPLES=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF \
        -DCMAKE_PREFIX_PATH="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
        -DCMAKE_CXX_FLAGS="${INTERNALL_BUILD_FLAGS}" \
        .. \
    && cmake --build . --config Release --target install \
    && cd / \
    && rm -rf /tmp/or-tools /tmp/or-tools.tar.gz

# TOML install (L375-L384): range-v3 0.12.0 is header-only.
RUN cd /tmp \
    && wget -q -O range-v3.tar.gz \
        "https://github.com/ericniebler/range-v3/archive/refs/tags/${RANGE_V3_VERSION}.tar.gz" \
    && mkdir -p range-v3 \
    && tar -I pigz -xf range-v3.tar.gz -C range-v3 --strip-components=1 \
    && cp -Trf range-v3/include "${AC_INSTALL_DIR}/include" \
    && rm -rf /tmp/range-v3 /tmp/range-v3.tar.gz

# TOML install (L385-L399): unordered_dense 4.5.0 (CMake header only).
RUN cd /tmp \
    && wget -q -O unordered_dense.tar.gz \
        "https://github.com/martinus/unordered_dense/archive/refs/tags/v${UNORDERED_DENSE_VERSION}.tar.gz" \
    && mkdir -p unordered_dense \
    && tar -I pigz -xf unordered_dense.tar.gz -C unordered_dense --strip-components=1 \
    && cd unordered_dense \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        .. \
    && cmake --build . --target install \
    && cd / \
    && rm -rf /tmp/unordered_dense /tmp/unordered_dense.tar.gz

# TOML install (L400-L416): Z3 4.15.2 (CMake build).
RUN cd /tmp \
    && wget -q -O z3.tar.gz \
        "https://github.com/Z3Prover/z3/archive/refs/tags/z3-${Z3_VERSION}.tar.gz" \
    && mkdir -p z3 \
    && tar -I pigz -xf z3.tar.gz -C z3 --strip-components=1 \
    && cd z3 \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        -DCMAKE_CXX_FLAGS="${INTERNALL_BUILD_FLAGS}" \
        .. \
    && cmake --build . --target install \
    && cd / \
    && rm -rf /tmp/z3 /tmp/z3.tar.gz

# TOML install (L417-L426): pre-compile std and std.compat modules into
# `gcm.cache/` under the workdir. GCC 15's `bits/std.cc` and
# `bits/std.compat.cc` ship inside `${AC_INSTALL_DIR}/include/c++/15.2.0/`;
# `-fsearch-include-path` resolves the relative paths against the
# compiler's include search list. Output goes to `/judge/gcm.cache/`,
# which g++ auto-discovers when the user submission compiles with
# `-fmodules` from the same workdir at submission time.
RUN cd /judge \
    && g++ bits/std.cc bits/std.compat.cc \
        -DATCODER -DONLINE_JUDGE -O2 -Wall -Wextra \
        -fconstexpr-depth=1024 -fconstexpr-loop-limit=524288 -fconstexpr-ops-limit=2097152 \
        -flto=auto -fmodules -ftrivial-auto-var-init=zero -march=native -pthread -std=gnu++23 \
        -Wl,--as-needed \
        "-L${AC_INSTALL_DIR}/lib64" "-Wl,-R${AC_INSTALL_DIR}/lib64" \
        -c -fmodule-only -fsearch-include-path

# TOML install (L427-L434): finalize — strip cmake/ and pkgconfig/
# subdirectories from the install prefix (saves a few hundred MB) and
# purge the build-only apt packages.
RUN find "${AC_INSTALL_DIR}" \( -name cmake -or -name pkgconfig \) -type d -print0 \
        | xargs -0 rm -rf \
    && apt-get purge -y --auto-remove git cmake lld ninja-build pigz pbzip2 wget xz-utils unzip bzip2 \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: replicate the TOML compile + execute end-to-end. Uses a
# minimal C++23 program exercising `std::println` (libstdc++ module) and
# the std module precompile in `gcm.cache/`. The full 149-library link
# chain is what the AtCoder judge actually runs at submission time;
# replicating it here would require ~20 KB of flags and add little
# coverage proportional to the maintenance cost. A working compile/run
# with the std module proves the toolchain is functional.
RUN cd /judge \
    && printf '%s\n' \
        'import std;' \
        'int main() {' \
        '    std::println("Hello, C++23 (GCC)!");' \
        '    return 0;' \
        '}' > Main.cpp \
    && g++ Main.cpp -o a.out \
        -DATCODER -DONLINE_JUDGE -O2 -Wall -Wextra \
        -fconstexpr-depth=1024 -fconstexpr-loop-limit=524288 -fconstexpr-ops-limit=2097152 \
        -flto=auto -fmodules -ftrivial-auto-var-init=zero -march=native -pthread -std=gnu++23 \
        -Wl,--as-needed \
        "-L${AC_INSTALL_DIR}/lib64" "-Wl,-R${AC_INSTALL_DIR}/lib64" \
        "-L${AC_INSTALL_DIR}/lib" "-Wl,-R${AC_INSTALL_DIR}/lib" \
        -fopenmp -lstdc++exp \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = "Hello, C++23 (GCC)!" ] \
    && rm -f Main.cpp a.out
