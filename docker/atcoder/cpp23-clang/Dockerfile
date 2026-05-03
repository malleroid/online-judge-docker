FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG LLVM_VERSION=21.1.0
ARG ABSEIL_VERSION=20250512.1
ARG AC_LIBRARY_VERSION=1.6
ARG BOOST_VERSION=1.88.0
ARG EIGEN_APT_VERSION=3.4.0-4
ARG GMP_APT_VERSION=2:6.3.0+dfsg-2ubuntu6.1
ARG IMMER_VERSION=0.8.1
ARG LIGHTGBM_VERSION=4.6.0
ARG ORTOOLS_VERSION=9.14
ARG RANGE_V3_VERSION=0.12.0
ARG UNORDERED_DENSE_VERSION=4.5.0
ARG Z3_VERSION=4.15.2

# The TOML hardcodes `--target=x86_64-unknown-linux-gnu` in boost's b2
# cxxflags and `-Wl,-R::install_dir::/lib/x86_64-unknown-linux-gnu`
# throughout the compile path. AtCoder's judge runs amd64 only, and
# arm64 would require rewriting all those paths plus rebuilding 11
# libraries against a different target triple. Build with:
#   docker build --platform linux/amd64

ENV AC_INSTALL_DIR=/opt/atcoder/clang
ENV PATH=/opt/atcoder/clang/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# The TOML's install script uses bash-only parameter expansions
# (`${BOOST_VERSION//./_}`, `${CMAKE_PATH//'/'/'\/'}`) that fail under
# dash. Switching the Dockerfile shell to bash mirrors the TOML's
# original interpreter and keeps the substitutions byte-aligned.
SHELL ["/bin/bash", "-c"]

WORKDIR /judge

# TOML install (L78-L85): set up /etc/atcoder/install_dir.txt + apt
# build tools. The TOML's `apt-get install -y git cmake lld
# ninja-build pigz pbzip2` is preserved verbatim; `wget xz-utils
# unzip ca-certificates` are added beyond the TOML for the bare
# ubuntu:24.04 image (the AtCoder judge image carries them
# implicitly). OpenMP is *not* installed via apt — Ubuntu's
# `libomp-dev` is LLVM 18 lineage and lives at
# `/usr/lib/x86_64-linux-gnu/libomp.so`, which the prebuilt LLVM's
# `ld.lld` does not search by default. Instead, OpenMP runtime is
# built from the matching `llvm-project-21.1.0.src.tar.xz` source in
# a dedicated step below so the ABI matches Clang 21 and the library
# lands under `${AC_INSTALL_DIR}/lib/` (already on the rpath).
# `libxml2 libc6-dev libgcc-14-dev` mirror the c23-clang Dockerfile —
# LLVM tarball link path needs them. `libstdc++-14-dev` is added on
# top because boost's `bootstrap.sh` builds the b2 engine using
# default `clang++` (no `-stdlib=` override), and the default stdlib
# is libstdc++ — without its headers (`<memory>` etc.) the bootstrap
# aborts. `binutils` provides the default `ld` linker that the same
# bootstrap clang++ invocation tries to spawn (LLVM ships `lld` but
# does not register it as `ld`). The final boost libraries are still
# built against libc++ via the explicit `-stdlib=libc++` in
# `INTERNALL_BUILD_FLAGS`.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        xz-utils \
        unzip \
        git \
        cmake \
        lld \
        ninja-build \
        pigz \
        pbzip2 \
        binutils \
        python3 \
        libxml2 \
        libc6-dev \
        libgcc-14-dev \
        libstdc++-14-dev \
    && mkdir -p /etc/atcoder \
    && echo "${AC_INSTALL_DIR}" > /etc/atcoder/install_dir.txt \
    && mkdir -p "${AC_INSTALL_DIR}/include" "${AC_INSTALL_DIR}/lib"

# TOML install (L136-L168): the TOML source-builds Clang/LLVM 21.1.0
# from `llvm-project-21.1.0.src.tar.xz`. We replace this with the
# LLVM official prebuilt tarball — same ~90 min build saved, and the
# tarball ships clang + lld + libc++ + libcxxabi + libunwind +
# compiler-rt + share/libc++/v1/std.cppm together. The deviation is
# noted in the comment above; it is accepted because the existing
# `c23-clang` and `llvm-ir` images use the same tarball pattern.
RUN cd /tmp \
    && wget -q -O llvm.tar.xz \
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz" \
    && tar --strip-components=1 -C "${AC_INSTALL_DIR}" -xJf llvm.tar.xz \
    && ldconfig \
    && rm llvm.tar.xz

# TOML install (L169-L175): auto-generate `bits/stdc++.h` by listing
# every libc++ header (excluding internal `__*` and dotted ones) and
# emitting `#include <header>` lines. Mirrors the TOML's `find ...
# -exec echo ... | tee` shell pipeline.
RUN mkdir -p "${AC_INSTALL_DIR}/include/bits" \
    && find "${AC_INSTALL_DIR}/include/c++/v1" -maxdepth 1 -type f \
        ! -iname '__*' ! -iname '*.*' \
        -exec basename {} \; \
        | awk '{print "#include <" $0 ">"}' \
        > "${AC_INSTALL_DIR}/include/bits/stdc++.h"

# Shared cxxflags for library builds (TOML's `INTERNALL_BUILD_FLAGS`,
# verbatim minus `::install_dir::` substitution). The trailing `-w`
# suppresses warnings during library compile so the build noise stays
# manageable.
# `-L${AC_INSTALL_DIR}/lib/x86_64-unknown-linux-gnu` is added beyond the
# TOML's INTERNALL_BUILD_FLAGS so ld.lld's *link-time* search reaches
# the libomp.so we built into that directory. The TOML keeps only the
# `-Wl,-R...` rpath (runtime search) because the AtCoder env source-
# builds LLVM with libomp in clang's default lib search; with the
# prebuilt LLVM tarball, clang does not search `<install>/lib/<triple>`
# by default at link time, so cmake's `FindOpenMP` try_compile fails
# without an explicit `-L`.
ENV INTERNALL_BUILD_FLAGS="-fuse-ld=lld -rtlib=compiler-rt -std=gnu++23 -stdlib=libc++ -unwindlib=libunwind -w -L/opt/atcoder/clang/lib/x86_64-unknown-linux-gnu -Wl,-R/opt/atcoder/clang/lib/x86_64-unknown-linux-gnu -Wl,-R/opt/atcoder/clang/lib/clang/20/lib/x86_64-unknown-linux-gnu"

# Beyond the TOML — build OpenMP runtime from the matching LLVM 21.1.0
# source. The prebuilt LLVM tarball above ships clang+lld+libc++ but
# omits `libomp.so` and `omp.h`; the AtCoder TOML's downstream library
# builds (`lightgbm`, `or-tools`) compile with `-fopenmp` and the cmake
# compiler-test fails to link `-lomp` without it. Building OpenMP from
# the same `llvm-project-21.1.0.src.tar.xz` the TOML's full LLVM source
# build references keeps the OpenMP runtime ABI aligned with Clang 21,
# without paying for the full 90-minute LLVM rebuild.
RUN cd /tmp \
    && wget -q -O llvm-project.tar.xz \
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz" \
    && tar -I 'xz -T0' -xf llvm-project.tar.xz \
    && cd "llvm-project-${LLVM_VERSION}.src/openmp" \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib/x86_64-unknown-linux-gnu \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        -DLIBOMP_ENABLE_SHARED=ON \
        .. \
    && cmake --build . --target install \
    && cd /tmp \
    && rm -rf "llvm-project-${LLVM_VERSION}.src" llvm-project.tar.xz

# TOML install (L189-L214): abseil 20250512.1 with `-fPIC` so or-tools
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
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
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

# TOML install (L215-L224): ac-library 1.6 is header-only — copy the
# `atcoder/` headers tree directly into the install prefix.
RUN cd /tmp \
    && wget -q -O ac-library.tar.gz \
        "https://github.com/atcoder/ac-library/archive/refs/tags/v${AC_LIBRARY_VERSION}.tar.gz" \
    && mkdir -p ac-library \
    && tar -I pigz -xf ac-library.tar.gz -C ac-library --strip-components=1 \
    && cp -rf ac-library/atcoder "${AC_INSTALL_DIR}/include" \
    && rm -rf /tmp/ac-library /tmp/ac-library.tar.gz

# TOML install (L225-L262): boost 1.88.0 with bootstrap.sh + b2.
# `link=static threading=single` matches the TOML; the
# `--target=x86_64-unknown-linux-gnu` flag forces clang to use the
# matching libcxx ABI. `mpi/graph_parallel/python` are excluded
# verbatim from the TOML.
RUN cd /tmp \
    && wget -q -O boost.tar.bz2 \
        "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.bz2" \
    && mkdir -p boost \
    && tar -I pbzip2 -xf boost.tar.bz2 -C boost --strip-components=1 \
    && cd boost \
    && echo "using clang : : clang++ ;" > user-config.jam \
    && ./bootstrap.sh \
        --with-toolset=clang \
        --without-libraries=mpi,graph_parallel,python \
        --prefix="${AC_INSTALL_DIR}" \
    && ./b2 \
        toolset=clang \
        link=static \
        threading=single \
        variant=release \
        cflags="-w" \
        cxxflags="${INTERNALL_BUILD_FLAGS} --target=x86_64-unknown-linux-gnu" \
        --user-config=./user-config.jam \
        -j"$(nproc)" -d0 \
        install \
    && cd / \
    && rm -rf /tmp/boost /tmp/boost.tar.bz2

# TOML install (L263-L284): Eigen3 via apt copy hack. The TOML pins
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

# TOML install (L285-L290): GMP 6.3.0 via apt direct (no relocate).
RUN apt-get install -y --no-install-recommends "libgmp3-dev=${GMP_APT_VERSION}"

# TOML install (L291-L301): immer 0.8.1 is header-only.
RUN cd /tmp \
    && wget -q -O immer.tar.gz \
        "https://github.com/arximboldi/immer/archive/refs/tags/v${IMMER_VERSION}.tar.gz" \
    && mkdir -p immer \
    && tar -I pigz -xf immer.tar.gz -C immer --strip-components=1 \
    && cp -Trf immer/immer "${AC_INSTALL_DIR}/include/immer" \
    && rm -rf /tmp/immer /tmp/immer.tar.gz

# TOML install (L302-L316): LibTorch is skipped for the clang variant
# (TOML L304 short-circuits when AC_VARIANT==clang). Mirror that:
# nothing to do here, just a placeholder comment for traceability.

# TOML install (L317-L338): LightGBM 4.6.0 with `BUILD_STATIC_LIB=ON`,
# `USE_HOMEBREW_FALLBACK=OFF`. `lightgbm` (CLI dir) and
# `external_libs/eigen` are removed before build to force the system
# Eigen we just installed to be picked up.
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
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DBUILD_CLI=OFF \
        -DBUILD_STATIC_LIB=ON \
        -DUSE_HOMEBREW_FALLBACK=OFF \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        -DCMAKE_CXX_FLAGS="${INTERNALL_BUILD_FLAGS} -I${AC_INSTALL_DIR}/include -fopenmp" \
        -DOpenMP_C_FLAGS="-fopenmp" \
        -DOpenMP_C_LIB_NAMES="omp" \
        -DOpenMP_CXX_FLAGS="-fopenmp" \
        -DOpenMP_CXX_LIB_NAMES="omp" \
        -DOpenMP_omp_LIBRARY="${AC_INSTALL_DIR}/lib/x86_64-unknown-linux-gnu/libomp.so" \
        .. \
    && cmake --build . --target install \
    && cd / \
    && rm -rf /tmp/lightgbm /tmp/lightgbm.tar.gz

# TOML install (L339-L372): OR-Tools 9.14 — the heaviest single build.
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
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
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

# TOML install (L373-L382): range-v3 0.12.0 is header-only.
RUN cd /tmp \
    && wget -q -O range-v3.tar.gz \
        "https://github.com/ericniebler/range-v3/archive/refs/tags/${RANGE_V3_VERSION}.tar.gz" \
    && mkdir -p range-v3 \
    && tar -I pigz -xf range-v3.tar.gz -C range-v3 --strip-components=1 \
    && cp -Trf range-v3/include "${AC_INSTALL_DIR}/include" \
    && rm -rf /tmp/range-v3 /tmp/range-v3.tar.gz

# TOML install (L383-L397): unordered_dense 4.5.0 (CMake header only).
RUN cd /tmp \
    && wget -q -O unordered_dense.tar.gz \
        "https://github.com/martinus/unordered_dense/archive/refs/tags/v${UNORDERED_DENSE_VERSION}.tar.gz" \
    && mkdir -p unordered_dense \
    && tar -I pigz -xf unordered_dense.tar.gz -C unordered_dense --strip-components=1 \
    && cd unordered_dense \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        .. \
    && cmake --build . --target install \
    && cd / \
    && rm -rf /tmp/unordered_dense /tmp/unordered_dense.tar.gz

# TOML install (L398-L414): Z3 4.15.2 (CMake build).
RUN cd /tmp \
    && wget -q -O z3.tar.gz \
        "https://github.com/Z3Prover/z3/archive/refs/tags/z3-${Z3_VERSION}.tar.gz" \
    && mkdir -p z3 \
    && tar -I pigz -xf z3.tar.gz -C z3 --strip-components=1 \
    && cd z3 \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${AC_INSTALL_DIR}" \
        -DCMAKE_INSTALL_MESSAGE=NEVER \
        -DCMAKE_CXX_FLAGS="${INTERNALL_BUILD_FLAGS}" \
        .. \
    && cmake --build . --target install \
    && cd / \
    && rm -rf /tmp/z3 /tmp/z3.tar.gz

# TOML install (L415-L424): pre-compile std module + std.compat module
# into /judge/std.pcm and /judge/std.compat.pcm. The TOML's compile
# step pulls these in via `-fprebuilt-module-path=.`, so they live at
# the workdir where the user's `Main.cpp` will be compiled.
RUN cd /judge \
    && clang++ "${AC_INSTALL_DIR}/share/libc++/v1/std.cppm" \
        -o std.pcm -Wno-reserved-module-identifier --precompile \
        -DATCODER -DONLINE_JUDGE -O2 -Wall -Wextra \
        -fconstexpr-depth=1024 -fconstexpr-steps=524288 \
        -fexperimental-library -flto=auto -fprebuilt-module-path=. \
        -ftrivial-auto-var-init=zero -fuse-ld=lld -march=native -pthread \
        -rtlib=compiler-rt -std=gnu++23 -stdlib=libc++ -unwindlib=libunwind \
        -Wl,--as-needed \
        "-Wl,-R${AC_INSTALL_DIR}/lib/x86_64-unknown-linux-gnu" \
        "-Wl,-R${AC_INSTALL_DIR}/lib/clang/20/lib/x86_64-unknown-linux-gnu" \
        -fopenmp -fopenmp-extensions \
    && clang++ "${AC_INSTALL_DIR}/share/libc++/v1/std.compat.cppm" \
        -o std.compat.pcm -Wno-reserved-module-identifier --precompile \
        -DATCODER -DONLINE_JUDGE -O2 -Wall -Wextra \
        -fconstexpr-depth=1024 -fconstexpr-steps=524288 \
        -fexperimental-library -flto=auto -fprebuilt-module-path=. \
        -ftrivial-auto-var-init=zero -fuse-ld=lld -march=native -pthread \
        -rtlib=compiler-rt -std=gnu++23 -stdlib=libc++ -unwindlib=libunwind \
        -Wl,--as-needed \
        "-Wl,-R${AC_INSTALL_DIR}/lib/x86_64-unknown-linux-gnu" \
        "-Wl,-R${AC_INSTALL_DIR}/lib/clang/20/lib/x86_64-unknown-linux-gnu" \
        -fopenmp -fopenmp-extensions

# TOML install (L425-L431): finalize — strip cmake/ and pkgconfig/
# subdirectories from the install prefix (saves a few hundred MB) and
# purge the build-only apt packages. The libomp runtime built from
# llvm-project source above is under `${AC_INSTALL_DIR}` and stays.
RUN find "${AC_INSTALL_DIR}" \( -name cmake -or -name pkgconfig \) -type d -print0 \
        | xargs -0 rm -rf \
    && apt-get purge -y --auto-remove git cmake lld ninja-build pigz pbzip2 wget xz-utils unzip \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: replicate the TOML compile + execute end-to-end. Uses a
# minimal C++23 program exercising `std::println` (libc++ module) and
# the std module precompile. The full 149-library link chain is what
# the AtCoder judge actually executes; replicating it here would
# require ~20 KB of flags. We keep the smoke test minimal — a working
# compile/run with the std module proves the toolchain is functional.
RUN printf '%s\n' \
        'import std;' \
        'int main() {' \
        '    std::println("Hello, C++23!");' \
        '    return 0;' \
        '}' > Main.cpp \
    && clang++ /judge/std.pcm /judge/std.compat.pcm ./Main.cpp -o a.out \
        -DATCODER -DONLINE_JUDGE \
        -I"${AC_INSTALL_DIR}/include" -O2 -Wall -Wextra \
        -fconstexpr-depth=1024 -fconstexpr-steps=524288 \
        -fexperimental-library -flto=auto -fprebuilt-module-path=. \
        -ftrivial-auto-var-init=zero -fuse-ld=lld -march=native -pthread \
        -rtlib=compiler-rt -std=gnu++23 -stdlib=libc++ -unwindlib=libunwind \
        -Wl,--as-needed \
        "-Wl,-R${AC_INSTALL_DIR}/lib/x86_64-unknown-linux-gnu" \
        "-Wl,-R${AC_INSTALL_DIR}/lib/clang/20/lib/x86_64-unknown-linux-gnu" \
        -fopenmp -fopenmp-extensions \
        "-L${AC_INSTALL_DIR}/lib" \
        "-L${AC_INSTALL_DIR}/lib/x86_64-unknown-linux-gnu" \
        "-Wl,-R${AC_INSTALL_DIR}/lib" \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = "Hello, C++23!" ] \
    && rm -f Main.cpp a.out
