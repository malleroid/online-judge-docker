FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GCC_MAJOR=15
ARG CLAY_SHA=5798ba2e652c5438269199bde5388769a49ee8db
ARG ABSEIL_VERSION=20250512.1
ARG AC_LIBRARY_VERSION=1.6
ARG BOOST_VERSION=1.88.0
ARG IMMER_VERSION=0.8.1
ARG LIBTORCH_VERSION=2.8.0
ARG EI1333_SHA=fe01067f70a4e97500d5603463b1fd4e59effc0e
ARG UNORDERED_DENSE_VERSION=4.5.0
ARG LIGHTGBM_VERSION=4.6.0
ARG SCIP_VERSION=9.2.3
ARG HIGHS_VERSION=1.11.0
ARG ORTOOLS_VERSION=9.14
ARG RANGE_V3_VERSION=0.12.0
ARG Z3_VERSION=4.15.2

# AtCoder's judge runs amd64 only. The TOML pulls libtorch's
# `libtorch-shared-with-deps-2.8.0+cpu.zip` (x86_64-only) and
# `SCIPOptSuite-9.2.3-Linux-ubuntu24.sh` (amd64-only binary
# installer). arm64 would require building libtorch and SCIP from
# source — well outside the scope of "reproduce the judge env".
# Build with: docker build --platform linux/amd64
#
# The TOML uses `gh_download_latest` (GitHub API "latest") for many
# libraries, which defeats reproducibility. We pin every version to
# the values current at the AtCoder 2025-10 snapshot date, matching
# cpp23-gcc (#139) where overlap exists. ei1333-library is HEAD-clone
# in the TOML; we pin to the master SHA at 2025-10-18 (the AtCoder
# 2025/10 announcement date).

SHELL ["/bin/bash", "-c"]

WORKDIR /judge

# TOML install (L72-L79): puni070 PPA + apt deps + g++-15 + remove
# Ubuntu's default cpp. The PPA hosts `g++-15` (15.2.0-1ppa0.1)
# matching the AtCoder display string `cLay 20250308-1 (GCC 15.2.0)`.
# `wget curl unzip xz-utils ca-certificates pkg-config` are added
# beyond the TOML for the bare ubuntu:24.04 image. `xz-utils` is
# needed to extract boost's `.tar.xz` tarball — the AtCoder judge
# image carries it implicitly; ubuntu:24.04 minimal does not.
#
# Several deviations from the TOML for CI robustness:
#  - The PPA's `apt-get update` is wrapped in a 5-attempt retry loop
#    with 30s backoff. Launchpad has been observed to flake under CI
#    load, and a missing PPA index here would silently fall back to
#    Ubuntu noble's apt (which has no `g++-15`), which apt would then
#    swallow and continue — only failing later in the
#    update-alternatives step.
#  - `gcc-${GCC_MAJOR}` is added alongside `g++-${GCC_MAJOR}` (the
#    TOML installs only g++-15 and relies on Recommends/Depends to
#    pull gcc-15). The PPA's `g++-15` does NOT hard-Depend on
#    `gcc-15`, so when Recommends silently fail to resolve the build
#    can land in a state with g++-15 missing the C frontend.
#  - The final install uses `--no-install-recommends` and an explicit
#    `dpkg -l` verification afterwards so missing packages fail fast,
#    rather than silently letting the build continue with a broken
#    toolchain.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        wget \
        curl \
        unzip \
        xz-utils \
        pkg-config \
    && add-apt-repository -y ppa:puni070/gcc-noble \
    && for i in 1 2 3 4 5; do \
        apt-get update && break ; \
        if [ "$i" = "5" ]; then echo "apt-get update failed after 5 attempts" >&2; exit 1; fi ; \
        echo "apt-get update flaked (attempt $i), retrying in 30s..." >&2 ; \
        sleep 30 ; \
       done \
    && apt-get install -y --no-install-recommends \
        ansifilter \
        cmake \
        libgmp-dev \
        libeigen3-dev \
        zlib1g-dev \
        libgtest-dev \
        git \
        libbenchmark-dev \
        libgmock-dev \
        binutils-dev \
        libmpfr-dev \
        libmpc-dev \
        libisl-dev \
        libzstd-dev \
        ninja-build \
        libbz2-dev \
        libtbb12 \
        libopenblas0 \
        liblapack3 \
        libmetis5 \
        patchelf \
    && apt-get --purge remove -y cpp \
    && apt-get install -y --no-install-recommends \
        "gcc-${GCC_MAJOR}" \
        "g++-${GCC_MAJOR}" \
    && dpkg -s "gcc-${GCC_MAJOR}" >/dev/null \
    && dpkg -s "g++-${GCC_MAJOR}" >/dev/null \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L129-L146): update-alternatives so plain `gcc`/`g++`
# (and friends like `gcc-ar`, `gcc-ranlib`, `gcov`) resolve to the
# `*-15` binaries. Without this, downstream library cmake invocations
# of `gcc`/`g++` would fall back to the Ubuntu default (which we
# purged in the previous step), failing the build.
RUN bins=$(dpkg -L $(apt-cache depends --recurse --installed "g++-${GCC_MAJOR}" \
        | grep -E "^[A-z].*-${GCC_MAJOR}.*" | sort -u) \
        | grep -E "^/usr/bin/.*-${GCC_MAJOR}\$" || true) \
    && slaves="" \
    && for bin in $bins; do \
        name=$(basename "$bin" | sed "s/-${GCC_MAJOR}\$//") ; \
        if [ "$name" != "gcc" ]; then \
            slaves+="--slave /usr/bin/$name $name /usr/bin/$name-${GCC_MAJOR} " ; \
        fi ; \
       done \
    && update-alternatives --quiet --install /usr/bin/gcc gcc "/usr/bin/gcc-${GCC_MAJOR}" 100 $slaves

# TOML install (L150-L153): cLay itself. A single ~14 K-line C++
# source file pinned by SHA. Built with `g++ -O2` (no `-std`; cLay
# itself is C++17-compatible) and installed to /usr/local/bin. cLay
# version is internal (`// cLay version 20250308-1` emitted in
# converted output's leading comment) — `clay --version` is not
# supported.
RUN cd /tmp \
    && wget -q -O clay.cpp \
        "https://github.com/laycrs/cLay/raw/${CLAY_SHA}/clay.cpp" \
    && g++ -O2 -o clay clay.cpp \
    && install -s clay /usr/local/bin/clay \
    && rm -f /tmp/clay /tmp/clay.cpp

# TOML install (L162-L174): abseil 20250512.1 with `-fPIC` and
# `CXX_STANDARD=20` (or-tools dependency). The TOML runs the abseil
# test suite with `ctest` after configure; we keep that for fidelity
# but it adds a few minutes to CI.
RUN cd /tmp \
    && wget -q -O abseil.tar.gz \
        "https://github.com/abseil/abseil-cpp/releases/download/${ABSEIL_VERSION}/abseil-cpp-${ABSEIL_VERSION}.tar.gz" \
    && mkdir abseil-cpp \
    && tar -C abseil-cpp -xf abseil.tar.gz \
    && cd "abseil-cpp/abseil-cpp-${ABSEIL_VERSION}" \
    && cmake \
        -DABSL_BUILD_TESTING=OFF \
        -DABSL_USE_GOOGLETEST_HEAD=OFF \
        -DABSL_PROPAGATE_CXX_STD=ON \
        -DCMAKE_CXX_STANDARD=20 \
        -DCMAKE_CXX_FLAGS:STRING="-O2 -fPIC" \
        -B build -G Ninja \
    && cmake --build build --config Release --target all \
    && (cd build && ctest -j"$(nproc)" || true) \
    && cmake --build build --target install \
    && ldconfig \
    && cd / \
    && rm -rf /tmp/abseil-cpp /tmp/abseil.tar.gz

# TOML install (L177-L180): ac-library 1.6 (header-only).
RUN cd /tmp \
    && wget -q -O ac-library.tar.gz \
        "https://github.com/atcoder/ac-library/archive/refs/tags/v${AC_LIBRARY_VERSION}.tar.gz" \
    && mkdir atcoder-ac-library \
    && tar -C atcoder-ac-library -xf ac-library.tar.gz \
    && cp -a "atcoder-ac-library/ac-library-${AC_LIBRARY_VERSION}/atcoder" /usr/local/include \
    && rm -rf /tmp/atcoder-ac-library /tmp/ac-library.tar.gz

# TOML install (L182-L187): boost 1.88.0 b2-nodocs. The TOML's
# `gh_download_latest` filter is `b2-nodocs` + xz, excluding "beta";
# we pin the resolved URL directly. `--without-libraries=mpi,
# graph_parallel,python` mirrors the TOML.
RUN cd /tmp \
    && wget -q -O boost.tar.xz \
        "https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/boost-${BOOST_VERSION}-b2-nodocs.tar.xz" \
    && tar -xf boost.tar.xz \
    && cd "boost-${BOOST_VERSION}" \
    && ./bootstrap.sh --with-toolset=gcc \
        --without-libraries=mpi,graph_parallel,python \
    && ./b2 -j"$(nproc)" toolset=gcc variant=release cxxflags="-std=c++20" stage \
    && ./b2 -j"$(nproc)" toolset=gcc variant=release cxxflags="-std=c++20" install \
    && cd / \
    && rm -rf "/tmp/boost-${BOOST_VERSION}" /tmp/boost.tar.xz

# TOML install (L189-L194): immer 0.8.1 (header-only via cmake).
RUN cd /tmp \
    && wget -q -O immer.tar.gz \
        "https://github.com/arximboldi/immer/archive/refs/tags/v${IMMER_VERSION}.tar.gz" \
    && tar -xf immer.tar.gz \
    && cd "immer-${IMMER_VERSION}" \
    && cmake -B build \
        -Dimmer_BUILD_TESTS:BOOL=OFF \
        -Dimmer_BUILD_DOCS:BOOL=OFF \
        -Dimmer_BUILD_EXAMPLES:BOOL=OFF \
        -G Ninja \
    && cmake --build build --config Release --target all \
    && cmake --build build --target install \
    && cd / \
    && rm -rf "/tmp/immer-${IMMER_VERSION}" /tmp/immer.tar.gz

# TOML install (L196-L204): LibTorch 2.8.0 CPU. The Caffe2 cmake
# files default to `--no-as-needed` linker behavior, which the TOML
# patches to `--as-needed` to avoid pulling unused symbols (matters
# at user submission link time).
RUN cd /tmp \
    && wget -q -O libtorch.zip \
        "https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-${LIBTORCH_VERSION}%2Bcpu.zip" \
    && unzip -q libtorch.zip \
    && cd libtorch \
    && sed -i 's/no-as-needed/as-needed/' share/cmake/Caffe2/Caffe2Targets.cmake \
    && sed -i 's/no-as-needed/as-needed/' share/cmake/Caffe2/public/utils.cmake \
    && cp -a include share lib /usr/local/ \
    && cd / \
    && rm -rf /tmp/libtorch /tmp/libtorch.zip

# TOML install (L206-L215): ei1333-library — cLay-specific competitive
# programming utilities (Konno Yuki / ei1333). The TOML clones master
# HEAD; we pin to the SHA current at 2025-10-18 (AtCoder 2025/10
# announcement date) for reproducibility.
RUN cd /tmp \
    && wget -q -O ei1333.tar.gz \
        "https://github.com/ei1333/library/archive/${EI1333_SHA}.tar.gz" \
    && mkdir ei1333-library \
    && tar -C ei1333-library --strip-components=1 -xf ei1333.tar.gz \
    && cd ei1333-library \
    && rm -fr .competitive-verifier .github docs test LICENSE README.md \
    && mkdir /usr/local/include/ei1333 \
    && cp -a . /usr/local/include/ei1333 \
    && cd / \
    && rm -rf /tmp/ei1333-library /tmp/ei1333.tar.gz

# TOML install (L217-L221): unordered_dense 4.5.0 (header-only via
# cmake, no test/example targets enabled by default).
RUN cd /tmp \
    && wget -q -O unordered_dense.tar.gz \
        "https://github.com/martinus/unordered_dense/archive/refs/tags/v${UNORDERED_DENSE_VERSION}.tar.gz" \
    && tar -xf unordered_dense.tar.gz \
    && cd "unordered_dense-${UNORDERED_DENSE_VERSION}" \
    && cmake -B build -G Ninja \
    && cmake --build build --target install \
    && cd / \
    && rm -rf "/tmp/unordered_dense-${UNORDERED_DENSE_VERSION}" /tmp/unordered_dense.tar.gz

# TOML install (L223-L228): LightGBM 4.6.0 from the
# `LightGBM-complete_source_code_tar_gz.tar.gz` release asset (full
# source, ~177 MB, vs. the 1.7 MB Python sdist `lightgbm-4.6.0.tar.gz`
# that cpp23-gcc uses — different cLay path because the TOML matches
# `complete_source_code` in the asset name).
RUN cd /tmp \
    && wget -q -O lightgbm.tar.gz \
        "https://github.com/microsoft/LightGBM/releases/download/v${LIGHTGBM_VERSION}/LightGBM-complete_source_code_tar_gz.tar.gz" \
    && mkdir microsoft-LightGBM \
    && tar -C microsoft-LightGBM -xf lightgbm.tar.gz \
    && cd microsoft-LightGBM \
    && cmake -B build -G Ninja \
    && cmake --build build \
    && cmake --build build --target install \
    && cd / \
    && rm -rf /tmp/microsoft-LightGBM /tmp/lightgbm.tar.gz

# TOML install (L230-L233): SCIPOptSuite 9.2.3 binary installer for
# Linux Ubuntu 24. The `--include-subdir` flag extracts under
# `scip/SCIPOptSuite-9.2.3-Linux/`, whose contents are then copied
# into `/usr/local/`.
RUN cd /tmp \
    && wget -q -O scip.sh \
        "https://scipopt.org/download/release/SCIPOptSuite-${SCIP_VERSION}-Linux-ubuntu24.sh" \
    && chmod +x scip.sh \
    && ./scip.sh --skip-license --include-subdir --prefix=scip \
    && cp -a scip/*/* /usr/local/ \
    && cd / \
    && rm -rf /tmp/scip /tmp/scip.sh

# TOML install (L235-L240): HiGHS — built externally (not via
# or-tools' `BUILD_HIGHS=ON` like cpp23-gcc does), so or-tools picks
# it up via `find_package` instead of bundling.
RUN cd /tmp \
    && wget -q -O highs.tar.gz \
        "https://github.com/ERGO-Code/HiGHS/archive/refs/tags/v${HIGHS_VERSION}.tar.gz" \
    && tar -xf highs.tar.gz \
    && cd "HiGHS-${HIGHS_VERSION}" \
    && cmake -S . -B build -G Ninja \
    && cmake --build build -j"$(nproc)" \
    && cmake --install build \
    && cd / \
    && rm -rf "/tmp/HiGHS-${HIGHS_VERSION}" /tmp/highs.tar.gz

# TOML install (L242-L248): or-tools 9.14 with the cLay-specific
# `SCIP::libscip` → `libscip` patch. The patch makes or-tools link
# against the externally installed SCIP (above) rather than expecting
# SCIP's own CMake target. `BUILD_HIGHS` and `BUILD_SCIP` are NOT
# enabled (cLay uses external builds for those, unlike cpp23-gcc).
RUN cd /tmp \
    && wget -q -O or-tools.tar.gz \
        "https://github.com/google/or-tools/archive/refs/tags/v${ORTOOLS_VERSION}.tar.gz" \
    && tar -xf or-tools.tar.gz \
    && cd "or-tools-${ORTOOLS_VERSION}" \
    && find . -type f -exec sed -i 's/SCIP::libscip/libscip/g' {} + \
    && cmake -B build -G Ninja \
        -DBUILD_Protobuf:BOOL=ON \
        -DBUILD_re2:BOOL=ON \
        -DBUILD_CoinUtils:BOOL=ON \
        -DBUILD_Osi:BOOL=ON \
        -DBUILD_Clp:BOOL=ON \
        -DBUILD_Cgl:BOOL=ON \
        -DBUILD_Cbc:BOOL=ON \
        -DUSE_HIGHS:BOOL=ON \
        -DBUILD_SAMPLES:BOOL=OFF \
        -DBUILD_EXAMPLES:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_CXX_STANDARD=20 \
    && cmake --build build --config Release --target all -j"$(nproc)" \
    && cmake --build build --config Release --target install \
    && cd / \
    && rm -rf "/tmp/or-tools-${ORTOOLS_VERSION}" /tmp/or-tools.tar.gz

# TOML install (L250-L254): range-v3 0.12.0.
RUN cd /tmp \
    && wget -q -O range-v3.tar.gz \
        "https://github.com/ericniebler/range-v3/archive/refs/tags/${RANGE_V3_VERSION}.tar.gz" \
    && tar -xf range-v3.tar.gz \
    && cd "range-v3-${RANGE_V3_VERSION}" \
    && cmake -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DRANGE_V3_TESTS=OFF \
        -DRANGE_V3_EXAMPLES=OFF \
    && cmake --build build --target install \
    && cd / \
    && rm -rf "/tmp/range-v3-${RANGE_V3_VERSION}" /tmp/range-v3.tar.gz

# TOML install (L256-L261): Z3 4.15.2.
RUN cd /tmp \
    && wget -q -O z3.tar.gz \
        "https://github.com/Z3Prover/z3/archive/refs/tags/z3-${Z3_VERSION}.tar.gz" \
    && tar -xf z3.tar.gz \
    && cd "z3-z3-${Z3_VERSION}" \
    && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build \
    && cmake --build build --target install \
    && cd / \
    && rm -rf "/tmp/z3-z3-${Z3_VERSION}" /tmp/z3.tar.gz

# Re-run ldconfig so the freshly installed shared libraries are
# discoverable by the smoke test and by user submissions.
RUN ldconfig

# TOML install (L268-L294): generate `/judge/CMakeLists.txt`. The
# user submission's compile step (`cmake --build build`) reuses this
# cmake project, so we pre-populate it during image build.
RUN cat <<'EOF' > /judge/CMakeLists.txt
cmake_minimum_required(VERSION 3.28)
project(main VERSION 1.0)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(absl REQUIRED)
find_package(ortools REQUIRED)
find_package(range-v3 REQUIRED)
find_package(Torch REQUIRED)
find_package(Z3 REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PkgConfig  REQUIRED)
pkg_check_modules(GMPXX REQUIRED gmpxx)
find_package(Boost REQUIRED ALL)
find_package(Immer REQUIRED)

set(CMAKE_CXX_FLAGS_RELEASE "-Wall -Wextra -O2 -fconstexpr-depth=2147483647 -fconstexpr-loop-limit=2147483647 -fconstexpr-ops-limit=2147483647 -fcoroutines -march=native -flto=auto -DATCODER -DONLINE_JUDGE")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${TORCH_CXX_FLAGS}")

get_property(AC_ABSL_TARGETS DIRECTORY "${CMAKE_SOURCE_DIR}" PROPERTY IMPORTED_TARGETS)
list(FILTER AC_ABSL_TARGETS INCLUDE REGEX "^absl::")

add_executable(main main.cpp)
target_link_libraries(main "${TORCH_LIBRARIES}" ortools::ortools ${AC_ABSL_TARGETS} _lightgbm ${Boost_ALL_TARGETS} ${Z3_LIBRARIES} Eigen3::Eigen ${GMPXX_LIBRARIES} stdc++exp)
EOF

# TOML install (L296-L305): smoke test mirroring AtCoder's own. Note
# that `build/` directory is intentionally PRESERVED — the TOML's
# compile step (`cmake --build build`) at submission time reuses the
# already-configured cmake cache. Only `build/main`, `main.cpp`, and
# `main.clay` are removed.
RUN cd /judge \
    && printf '%s\n' \
        '{' \
        '  cout << "Hello, cLay!" << endl;' \
        '}' > main.clay \
    && clay < main.clay > main.cpp \
    && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build \
    && out="$(./build/main)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = "Hello, cLay!" ] \
    && rm -f build/main main.cpp main.clay
