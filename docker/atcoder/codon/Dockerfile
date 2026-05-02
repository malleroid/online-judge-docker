FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG CPYTHON_VERSION=3.13.7
ARG CPYTHON_SHA256=5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a
ARG CODON_VERSION=0.19.3
ARG CODON_AMD64_SHA256=f27abda792c0c9f9a42d529c2e0a1b2113ec6964eec23d6f62acef9ed42c3de6
ARG AC_LIBRARY_PYTHON_REF=27fdbb71cd0d566bdeb12746db59c9d908c6b5d5

# The AtCoder TOML hardcodes `codon-linux-x86_64.tar.gz` and the
# pinned scientific Python wheels (numpy / scipy / scikit-learn /
# pandas / torch+cpu) target manylinux2014_x86_64. Build with:
#   docker build --platform linux/amd64

ENV CODON_PYTHON=/usr/local/lib/libpython3.13.so

WORKDIR /judge

# TOML install (L7-L11): build deps for CPython 3.13. The TOML
# specifies the package list verbatim and we mirror it.
# `libbolt-18-dev` is added beyond the TOML — the TOML installs only
# `llvm-bolt` (the bolt-18 binary), but the `--enable-bolt` CPython
# build symlinks `/usr/lib/llvm-18/lib/libbolt_rt_instr.a` (TOML L23)
# which lives in `libbolt-18-dev`, not `bolt-18`. Without it the
# CPython build aborts during BOLT instrumentation.
# `ca-certificates` is added because ubuntu:24.04 minimal lacks the
# CA bundle that the AtCoder judge image carries implicitly.
# `locales` is added because TOML L104 calls `locale-gen` which
# `locales` provides; it is preinstalled on the AtCoder judge image
# but not on ubuntu:24.04 minimal.
# `build-essential` is added because TOML's package list pulls `gcc`
# transitively (via libgcc-13-dev) but never `g++` — `cppyy-backend`
# (a freeze.txt dep of `cppyy`) compiles `clingwrapper.cxx` and
# fails with `g++: No such file or directory` without it. Same TOML
# omission pattern as Ruby (#126).
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        locales \
        build-essential \
        wget \
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
        libbolt-18-dev \
        ansifilter \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L13-L15): fetch the prebuilt Codon binary tarball
# from upstream GitHub Releases and unpack it under /usr/local. The
# TOML uses bare `wget` with no checksum — sha256 is added here
# (verified against the GitHub Release `digest` field).
RUN cd /tmp \
    && wget -q -O codon.tar.gz \
        "https://github.com/exaloop/codon/releases/download/v${CODON_VERSION}/codon-linux-x86_64.tar.gz" \
    && echo "${CODON_AMD64_SHA256}  codon.tar.gz" | sha256sum -c - \
    && tar -C /usr/local --strip-components=1 -xf codon.tar.gz \
    && rm codon.tar.gz

# TOML install (L17-L29): build CPython 3.13.7 from source with
# `--enable-optimizations --with-lto=full --with-strict-overflow
# --enable-bolt --enable-shared`, install via `make altinstall` so
# the binary lands at /usr/local/bin/python3.13. The `libbolt_rt_instr.a`
# symlink (TOML L23) makes the BOLT instrumentation pass find its
# runtime library at the path CPython's build expects.
RUN cd /tmp \
    && wget -q -O "Python-${CPYTHON_VERSION}.tar.xz" \
        "https://www.python.org/ftp/python/${CPYTHON_VERSION}/Python-${CPYTHON_VERSION}.tar.xz" \
    && echo "${CPYTHON_SHA256}  Python-${CPYTHON_VERSION}.tar.xz" | sha256sum -c - \
    && tar xf "Python-${CPYTHON_VERSION}.tar.xz" \
    && cd "Python-${CPYTHON_VERSION}" \
    && ln -s /usr/lib/llvm-18/lib/libbolt_rt_instr.a /usr/lib/libbolt_rt_instr.a \
    && ./configure --enable-optimizations --with-lto=full --with-strict-overflow --enable-bolt --enable-shared \
    && make -j"$(nproc)" \
    && make altinstall \
    && cd /tmp \
    && rm -rf "Python-${CPYTHON_VERSION}" "Python-${CPYTHON_VERSION}.tar.xz" \
    && ldconfig

# TOML install (L31-L78): generate freeze.txt verbatim from the TOML
# heredoc and pip-install it via the freshly built python3.13. The
# `ac-library-python` git+https URL is pinned to the same SHA the
# TOML uses (`27fdbb71...`). The `${AC_LIBRARY_PYTHON_REF}` ARG is
# expanded by the shell inside the heredoc (no quoting on `EOF`).
RUN cat <<EOF > /tmp/freeze.txt
absl-py==2.3.1
ac-library-python @ git+https://github.com/not522/ac-library-python@${AC_LIBRARY_PYTHON_REF}
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
RUN python3.13 -m pip install --no-warn-script-location -U setuptools pip \
    && python3.13 -m pip install -r /tmp/freeze.txt --no-warn-script-location \
    && rm /tmp/freeze.txt

# TOML install (L80): torch CPU build is published on the PyTorch
# wheel index, separate from PyPI. The `+cpu` local-version tag is
# only resolvable via that index.
RUN python3.13 -m pip install --no-warn-script-location \
        torch==2.8.0+cpu \
        --index-url https://download.pytorch.org/whl/cpu

# TOML install (L82-L88): numba 0.61.2 ships a `numba/cuda` subtree
# that requires CUDA toolchain at install time; the AtCoder TOML
# patches setup.py and removes the cuda dir to skip it. Pin via the
# upstream PyPI hashed URL (the per-package /<sha256>/ path is the
# de-facto sha256 pin).
RUN cd /tmp \
    && wget -q -O numba.tar.gz \
        https://files.pythonhosted.org/packages/1c/a0/e21f57604304aa03ebb8e098429222722ad99176a4f979d34af1d1ee80da/numba-0.61.2.tar.gz \
    && mkdir numba \
    && tar -C numba --strip-components=1 -xf numba.tar.gz \
    && cd numba \
    && sed -i 's/ext_cuda_extras, //' setup.py \
    && rm -fr numba/cuda \
    && python3.13 -m pip install --no-warn-script-location . \
    && cd /tmp \
    && rm -rf numba numba.tar.gz \
    && python3.13 -m pip cache purge

# TOML install (L104): generate the en_US.UTF-8 locale that
# `from python import` walks through during CPython initialisation.
RUN locale-gen en_US.UTF-8

# TOML install (L93-L102): smoke test source — verbatim from the
# TOML heredoc. `from python import atcoder.dsu` reaches into
# ac-library-python through Codon's Python interop, which is the
# most fragile path of the whole image (depends on CPython, Codon,
# the freeze.txt install, and locale all being aligned).
RUN cat <<'EOF' > /judge/Main.py
import sys
from python import atcoder.dsu as dsu

def main() -> None:
  d = dsu.DSU(10)
  d.merge(1, 2)
  print(d.groups())

main()
EOF

# TOML install (L105-L107): build with `codon build --release` and
# run, then clean up. `CODON_PYTHON` is set via `ENV` above so it
# persists across layers. The expected stdout is the DSU groups
# result for a 10-element DSU after merging 0..9 except 1 and 2:
# `[[0], [1, 2], [3], [4], [5], [6], [7], [8], [9]]`.
RUN cd /judge \
    && codon build --release -o a.out Main.py \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -q "\[1, 2\]" \
    && rm -f a.out Main.py
