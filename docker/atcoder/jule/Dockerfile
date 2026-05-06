FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GCC_MAJOR=15
ARG LLVM_VERSION=21.1.0
ARG JULE_VERSION=0.1.6
ARG JULE_SHA256=dab66372add13cd7d98a70fd0a446dd3d855e04f1d8a18e4e71d1a960961d72a
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
ARG Z3_VERSION=4.15.2

# AtCoder's judge runs amd64 only. The TOML pulls
# `jule-linux-amd64.zip` (x86_64-only), `libtorch-shared-with-deps-
# 2.8.0+cpu.zip` (x86_64-only), and `SCIPOptSuite-9.2.3-Linux-ubuntu24.sh`
# (amd64-only binary installer). Build with:
#   docker build --platform linux/amd64
#
# The TOML uses `gh_download_latest` (GitHub API "latest") for many
# libraries. We pin every version to the values current at the AtCoder
# 2025-10 snapshot date, matching cpp23-gcc (#139) / cLay (#140) /
# cpp23-clang (#136) where overlap exists.
#
# CI build time will be DOMINATED by the LLVM 21.1.0 source build with
# Polly + 6 runtimes (libc/libunwind/libcxxabi/libcxx/compiler-rt/openmp).
# Total expected build time: 100-160 minutes on `ubuntu-latest`. If the
# workflow's `timeout-minutes: 100` is exceeded, follow the SageMath
# playbook (#130 → #131) to bump the workflow timeout.
#
# Unlike cpp23-clang (#136) which uses the prebuilt LLVM tarball to skip
# the source build, this Dockerfile mirrors the TOML's full LLVM source
# build because the TOML enables Polly and writes
# `/etc/ld.so.conf.d/x86_64-unknown-linux-gnu.conf` for the multi-arch
# runtime path — the prebuilt tarball ships a different layout that
# would diverge from the AtCoder judge environment.

SHELL ["/bin/bash", "-c"]

WORKDIR /judge

# TOML install (L4-L11): puni070 PPA + apt deps + g++-15 + remove
# Ubuntu's default cpp. The PPA hosts `g++-15` (15.2.0-1ppa0.1) which
# is needed both as the host C++ compiler for the LLVM source build
# below and as the C++ compiler used by all 11 downstream library
# builds. `wget curl unzip xz-utils ca-certificates pkg-config` are
# added beyond the TOML for the bare ubuntu:24.04 image.
#
# Lessons from cLay (#140) — same PPA, same flake patterns:
#  - The PPA's `apt-get update` is wrapped in a 5-attempt retry loop
#    with 30s backoff. Launchpad has been observed to flake (and was
#    DDoS'd 2026-04-30 → 05-04).
#  - `gcc-15` is added explicitly alongside `g++-15` because the PPA's
#    `g++-15` does NOT hard-Depend on `gcc-15`.
#  - `--no-install-recommends` + `dpkg -s` verification means missing
#    packages fail fast.
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
        python3 \
    && apt-get --purge remove -y cpp \
    && apt-get install -y --no-install-recommends \
        "gcc-${GCC_MAJOR}" \
        "g++-${GCC_MAJOR}" \
    && dpkg -s "gcc-${GCC_MAJOR}" >/dev/null \
    && dpkg -s "g++-${GCC_MAJOR}" >/dev/null \
    && rm -rf /var/lib/apt/lists/*

# TOML install (update-alternatives helper expansion): make plain
# `gcc`/`g++` resolve to `*-15`. Required because we purged Ubuntu's
# default `cpp` above and downstream cmake/library builds (and the LLVM
# source build) invoke unsuffixed `gcc`/`g++`.
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

# TOML install (Jule binary): single-shot binary release. The asset is
# pinned by `JULE_SHA256` (locally verified). Layout under
# `/root/jule/`: `bin/julec` (compiler), `api/*.hpp` (runtime headers),
# `std/` (Jule stdlib including `std/jule/integrated` used by the
# smoke test). julec resolves `use "std/..."` paths relative to its
# own bin location, so the whole tree must stay co-located.
RUN cd /tmp \
    && wget -q -O jule.zip \
        "https://github.com/julelang/jule/releases/download/jule${JULE_VERSION}/jule-linux-amd64.zip" \
    && echo "${JULE_SHA256}  jule.zip" | sha256sum -c - \
    && unzip -q jule.zip -x '__MACOSX/*' -d /root \
    && rm /tmp/jule.zip
ENV PATH=/root/jule/bin:${PATH}

# TOML install (LLVM source build): Clang/LLVM 21.1.0 with Polly +
# all 6 runtimes (libc/libunwind/libcxxabi/libcxx/compiler-rt/openmp).
# This is the dominant build cost (~60-90 min on ubuntu-latest). The
# tarball URL is the GitHub API auto-archive (TOML L41-L42 verbatim),
# not the official `llvm-project-21.1.0.src.tar.xz` release tarball,
# so no upstream-published sha256 — we accept the unpinned download
# here; reproducibility is bounded by the AtCoder TOML itself.
# `LLVM_BINUTILS_INCDIR=/usr/include` enables LTO via the binutils
# plugin; `/etc/ld.so.conf.d/x86_64-unknown-linux-gnu.conf` registers
# the multi-arch runtime path so `ldconfig` resolves the new libc++.
# `-G Ninja` is added beyond the TOML — the AtCoder judge image has
# `make` pre-installed (cmake's default "Unix Makefiles" generator
# works there), but ubuntu:24.04 minimal does not, and the apt list
# above intentionally avoids `build-essential` to stay close to the
# TOML. We use the `ninja-build` package (already installed) instead.
RUN cd /tmp \
    && wget -q -O llvm.tar.gz \
        "https://api.github.com/repos/llvm/llvm-project/tarball/llvmorg-${LLVM_VERSION}" \
    && mkdir llvm-llvm-project \
    && tar -C llvm-llvm-project -xf llvm.tar.gz \
    && cd llvm-llvm-project/* \
    && cmake -S llvm -B build -G Ninja \
        -DLLVM_ENABLE_PROJECTS="clang;lld;polly" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
        -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
        -DLLVM_PARALLEL_TABLEGEN_JOBS="$(nproc)" \
        -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;compiler-rt;openmp" \
        -DLLVM_TARGETS_TO_BUILD=host \
        -DLLVM_BINUTILS_INCDIR=/usr/include \
    && cmake --build build -j"$(nproc)" \
    && cmake --build build --target install \
    && echo "/usr/local/lib/x86_64-unknown-linux-gnu" > /etc/ld.so.conf.d/x86_64-unknown-linux-gnu.conf \
    && ldconfig \
    && cd / \
    && rm -rf /tmp/llvm-llvm-project /tmp/llvm.tar.gz

# TOML install (abseil): 20250512.1 with `-fPIC` and `CXX_STANDARD=20`
# (or-tools dependency). Same as cLay #140; abseil's ctest tolerates
# transient failures with `--repeat until-pass:5` per the TOML.
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

# TOML install: ac-library 1.6 (header-only).
RUN cd /tmp \
    && wget -q -O ac-library.tar.gz \
        "https://github.com/atcoder/ac-library/archive/refs/tags/v${AC_LIBRARY_VERSION}.tar.gz" \
    && mkdir atcoder-ac-library \
    && tar -C atcoder-ac-library -xf ac-library.tar.gz \
    && cp -a "atcoder-ac-library/ac-library-${AC_LIBRARY_VERSION}/atcoder" /usr/local/include \
    && rm -rf /tmp/atcoder-ac-library /tmp/ac-library.tar.gz

# TOML install: boost 1.88.0 b2-nodocs. `--without-libraries=mpi,
# graph_parallel` mirrors the TOML (NOTE: TOML does NOT exclude
# `python` here, unlike cLay/cpp23-gcc — boost-python is built).
RUN cd /tmp \
    && wget -q -O boost.tar.xz \
        "https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/boost-${BOOST_VERSION}-b2-nodocs.tar.xz" \
    && tar -xf boost.tar.xz \
    && cd "boost-${BOOST_VERSION}" \
    && ./bootstrap.sh --with-toolset=gcc \
        --without-libraries=mpi,graph_parallel \
    && ./b2 -j"$(nproc)" toolset=gcc variant=release cxxflags="-std=c++20" stage \
    && ./b2 -j"$(nproc)" toolset=gcc variant=release cxxflags="-std=c++20" install \
    && cd / \
    && rm -rf "/tmp/boost-${BOOST_VERSION}" /tmp/boost.tar.xz

# TOML install: immer 0.8.1 (header-only via cmake).
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

# TOML install: LibTorch 2.8.0 CPU. Unlike cLay (#140) which patches
# Caffe2 cmake, the Jule TOML keeps Caffe2 as-is and instead places
# headers/libs under `/usr/local/{include,lib}/libtorch/` (subdirectory
# layout) and registers `/etc/ld.so.conf.d/libtorch.conf` so the
# loader finds the .so files at submission time.
RUN cd /tmp \
    && wget -q -O libtorch.zip \
        "https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-${LIBTORCH_VERSION}%2Bcpu.zip" \
    && unzip -q libtorch.zip \
    && cp -a libtorch/include /usr/local/include/libtorch \
    && cp -a libtorch/lib /usr/local/lib/libtorch \
    && echo /usr/local/lib/libtorch > /etc/ld.so.conf.d/libtorch.conf \
    && cd / \
    && rm -rf /tmp/libtorch /tmp/libtorch.zip

# TOML install: ei1333-library — competitive programming utilities.
# Same SHA pin as cLay (#140), same 2025-10-18 snapshot date.
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

# TOML install: unordered_dense 4.5.0.
RUN cd /tmp \
    && wget -q -O unordered_dense.tar.gz \
        "https://github.com/martinus/unordered_dense/archive/refs/tags/v${UNORDERED_DENSE_VERSION}.tar.gz" \
    && tar -xf unordered_dense.tar.gz \
    && cd "unordered_dense-${UNORDERED_DENSE_VERSION}" \
    && cmake -B build -G Ninja \
    && cmake --build build --target install \
    && cd / \
    && rm -rf "/tmp/unordered_dense-${UNORDERED_DENSE_VERSION}" /tmp/unordered_dense.tar.gz

# TOML install: LightGBM 4.6.0 from the `complete_source_code` asset.
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

# TOML install: SCIPOptSuite 9.2.3 binary installer.
RUN cd /tmp \
    && wget -q -O scip.sh \
        "https://scipopt.org/download/release/SCIPOptSuite-${SCIP_VERSION}-Linux-ubuntu24.sh" \
    && chmod +x scip.sh \
    && ./scip.sh --skip-license --include-subdir --prefix=scip \
    && cp -a scip/*/* /usr/local/ \
    && cd / \
    && rm -rf /tmp/scip /tmp/scip.sh

# TOML install: HiGHS — built externally, picked up by or-tools via
# `find_package`.
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

# TOML install: or-tools 9.14 with the `SCIP::libscip` → `libscip`
# patch. Same as cLay; or-tools links against externally installed SCIP.
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

# TOML install: Z3 4.15.2.
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

# Final ldconfig so the freshly installed shared libraries (LLVM
# runtimes, libtorch, abseil, …) are discoverable at smoke test time
# and at user submission time.
RUN ldconfig

# TOML install (smoke test): mirror the AtCoder install-time test
# verbatim. Exercises the full toolchain: julec resolves
# `std/jule/integrated`; the source-built clang++ accepts `-std=c++20`;
# `cpp use "<atcoder/dsu>"` finds ac-library at /usr/local/include;
# `cpp.dsu` C++ interop links and runs end-to-end. Expected output is
# `2\n1` (40-element DSU; merge(0,1) → component {0,1} size 2; node 2
# is its own component size 1). The `#pass "-O3"` and
# `#pass "-march=native"` directives in the source file land on the
# clang++ command line.
RUN cd /judge \
    && cat <<'EOF' > Main.jule
#pass "-O3"
#pass "-march=native"
use integ "std/jule/integrated"
cpp use "<atcoder/dsu>"

#typedef
#namespace "atcoder"
cpp struct dsu {
  merge: fn(int, int)
  size: fn(int): int
}

fn NewDsu(v: integ::Int): cpp.dsu {
    ret unsafe { integ::Emit[cpp.dsu]("atcoder::dsu({})", v) }
}

fn main() {
  let d = NewDsu(40)
  d.merge(0, 1)
  println(d.size(0))
  println(d.size(2))
}
EOF
RUN cd /judge \
    && /root/jule/bin/julec --cppstd cpp20 --opt L2 -p . 2>&1 | ansifilter \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = $'2\n1' ] \
    && rm -f Main.jule a.out
