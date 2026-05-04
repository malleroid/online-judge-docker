FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG AC_CPYTHON_VERSION=3.13.7
ARG AC_CPYTHON_SHA256=5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a
ARG AC_LIBRARY_PYTHON_REF=27fdbb71cd0d566bdeb12746db59c9d908c6b5d5
ARG NUMBA_VERSION=0.61.2
ARG NUMBA_SHA256=8750ee147940a6637b80ecf7f95062185ad8726c8c28a2295b8ec1160a196f7d

# The AtCoder TOML hardcodes amd64-only paths and dependencies:
# `--enable-bolt` requires `/usr/lib/llvm-18/lib/libbolt_rt_instr.a`,
# which Ubuntu 24.04 noble ships only on amd64. The pinned `torch
# ==2.8.0+cpu` PyPI wheels and bundled-cling `cppyy==3.5.0` likewise
# target amd64. arm64 would require regenerating BOLT runtimes, falling
# back to a different torch index, and rebuilding cppyy/cling from
# sdist — well beyond reproducing the judge env.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# TOML install (L7-L10): build deps for CPython source build
# (https://devguide.python.org/getting-started/setup-building/#build-dependencies).
# `ca-certificates`, `wget`, and `xz-utils` are added beyond the TOML
# — the AtCoder judge image carries them implicitly; ubuntu:24.04
# minimal does not, and we need them to download/extract the Python
# tarball over https.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
       apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        xz-utils \
        build-essential \
        gdb \
        lcov \
        pkg-config \
        libbz2-dev \
        libffi-dev \
        libgdbm-dev \
        libgdbm-compat-dev \
        liblzma-dev \
        libncurses5-dev \
        libreadline6-dev \
        libsqlite3-dev \
        libssl-dev \
        lzma \
        lzma-dev \
        tk-dev \
        uuid-dev \
        zlib1g-dev \
        git \
        llvm-bolt \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L18): symlink the BOLT instrumentation runtime into
# `/usr/lib/`. `./configure --enable-bolt` hard-codes that path and
# fails configure if it is missing. Must run BEFORE configure.
RUN ln -s /usr/lib/llvm-18/lib/libbolt_rt_instr.a /usr/lib/libbolt_rt_instr.a

# TOML install (L13-L24): download Python source tarball, configure
# with PGO + LTO + BOLT, build, and install via `altinstall` so the
# resulting binary lives at `/usr/local/bin/python3.13` and does not
# overwrite the system `python3`. sha256 is computed locally and pinned
# (python.org publishes only MD5; same pattern as docker/atcoder/apl).
RUN cd /tmp \
    && wget -q -O "Python-${AC_CPYTHON_VERSION}.tar.xz" \
        "https://www.python.org/ftp/python/${AC_CPYTHON_VERSION}/Python-${AC_CPYTHON_VERSION}.tar.xz" \
    && echo "${AC_CPYTHON_SHA256}  Python-${AC_CPYTHON_VERSION}.tar.xz" | sha256sum -c - \
    && tar xf "Python-${AC_CPYTHON_VERSION}.tar.xz" \
    && cd "Python-${AC_CPYTHON_VERSION}" \
    && ./configure --enable-optimizations --with-lto=full --with-strict-overflow --enable-bolt \
    && make -j"$(nproc)" \
    && make altinstall \
    && cd /tmp \
    && rm -rf "Python-${AC_CPYTHON_VERSION}" "Python-${AC_CPYTHON_VERSION}.tar.xz"

# TOML install (L70): upgrade pip and setuptools BEFORE installing
# freeze.txt — the freeze pins assume modern pip resolver / build
# isolation behavior.
RUN python3.13 -m pip install --no-warn-script-location -U setuptools pip

# TOML install (L27-L67, L72): write the freeze list verbatim and
# install. The 41 lines below are copied byte-for-byte from the TOML's
# freeze.txt heredoc — order matters because pip resolves alphabetically
# and changing the order can shift dependency resolution outcomes.
RUN cat <<'EOF' > /tmp/freeze.txt
absl-py==2.3.1
ac-library-python @ git+https://github.com/not522/ac-library-python@27fdbb71cd0d566bdeb12746db59c9d908c6b5d5
acl-cpp-python==0.6.2
bitarray==3.6.1
cppyy==3.5.0
cppyy-backend==1.15.3
cppyy-cling==6.32.8
CPyCppyy==1.13.0
Cython==3.1.3
filelock==3.19.1
fsspec==2025.7.0
gmpy2==2.2.1
immutabledict==4.2.1
Jinja2==3.1.6
joblib==1.5.1
lightgbm==4.6.0
llvmlite==0.44.0
MarkupSafe==3.0.2
more-itertools==10.7.0
mpmath==1.3.0
networkx==3.5
numpy==2.2.6
ortools==9.14.6206
pandas==2.3.2
polars==1.31.0
protobuf==6.31.1
PuLP==3.2.2
pyrsistent==0.20.0
python-dateutil==2.9.0.post0
pytz==2025.2
rustworkx==0.16.0
scikit-learn==1.7.1
scipy==1.16.1
shapely==2.1.1
six==1.17.0
sortedcontainers==2.4.0
sympy==1.14.0
threadpoolctl==3.6.0
typing_extensions==4.14.1
tzdata==2025.2
z3-solver==4.15.3.0
EOF
RUN python3.13 -m pip install -r /tmp/freeze.txt --no-warn-script-location

# TOML install (L74): PyTorch CPU build from the official PyTorch
# index. Kept as a separate layer so the slow torch download does not
# invalidate the freeze.txt cache on TOML touch-ups.
RUN python3.13 -m pip install --no-warn-script-location \
        --index-url https://download.pytorch.org/whl/cpu \
        torch==2.8.0+cpu

# TOML install (L76-L82): numba 0.61.2 sdist, with CUDA support
# stripped before install (`sed` removes the `ext_cuda_extras` setup
# dep, and `numba/cuda/` is deleted outright). Depends on
# `llvmlite==0.44.0` already installed in freeze.txt above. sha256 is
# from PyPI's published file digest.
RUN cd /tmp \
    && wget -q -O numba.tar.gz \
        "https://files.pythonhosted.org/packages/1c/a0/e21f57604304aa03ebb8e098429222722ad99176a4f979d34af1d1ee80da/numba-${NUMBA_VERSION}.tar.gz" \
    && echo "${NUMBA_SHA256}  numba.tar.gz" | sha256sum -c - \
    && mkdir numba \
    && tar -C numba --strip-components=1 -xf numba.tar.gz \
    && cd numba \
    && sed -i 's/ext_cuda_extras, //' setup.py \
    && rm -fr numba/cuda \
    && python3.13 -m pip install . \
    && cd /tmp \
    && rm -rf numba numba.tar.gz freeze.txt

# TOML install (L84): wipe pip cache to keep the image lean.
RUN python3.13 -m pip cache purge

# Smoke test: mirror the TOML compile + execute pipeline. The compile
# command runs the program once with `argv[1]=ONLINE_JUDGE` (a common
# AtCoder pattern for one-off pre-computation), and the execute uses
# `-X int_max_str_digits=0` to disable the Python 3.11+ str↔int digit
# limit. The program imports several pinned third-party libraries
# (numpy, scipy, networkx, sympy, pandas, polars, sortedcontainers,
# more_itertools, bitarray) so a regression breaking any of them
# surfaces during the build, not at submission time.
RUN printf '%s\n' \
        'import sys' \
        'import numpy, scipy, networkx, sympy, pandas, polars' \
        'import sortedcontainers, more_itertools, bitarray' \
        'mode = sys.argv[1] if len(sys.argv) > 1 else "RUN"' \
        'print(f"Hello, CPython! mode={mode}")' > Main.py \
    && python3.13 -m py_compile Main.py \
    && test -f ./__pycache__/Main.cpython-313.pyc \
    && python3.13 Main.py ONLINE_JUDGE 2> /dev/null \
    && out="$(python3.13 -X int_max_str_digits=0 Main.py)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = "Hello, CPython! mode=RUN" ] \
    && rm -f Main.py \
    && rm -rf __pycache__
