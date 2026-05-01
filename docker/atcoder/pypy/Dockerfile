FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG PYPY_VERSION=7.3.20
ARG PYPY_PYTHON_VERSION=3.11
ARG PYPY_AMD64_SHA256=1410db3a7ae47603e2b7cbfd7ff6390b891b2e041c9eb4f1599f333677bccb3e
ARG AC_LIBRARY_PYTHON_REF=27fdbb71cd0d566bdeb12746db59c9d908c6b5d5

# The AtCoder TOML hardcodes the `linux64` (amd64) PyPy tarball, and
# many of the pinned PyPy pip wheels (numpy / scipy / scikit-learn /
# pandas) are amd64-only — arm64 would fall back to sdist builds for
# most of the science stack plus cppyy's bundled cling fetch.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# TOML install (L2-L4): apt deps. The TOML splits this into two
# `apt-get install` calls (install-time `git wget bzip2`, then
# library build deps) — order is preserved by listing them in the
# same `apt-get install` here, since TOML's grouping is purely
# annotative and a single install call gives the same package set.
# `ca-certificates` is added beyond the TOML — the AtCoder judge
# image carries it implicitly; ubuntu:24.04 minimal does not, and
# `wget` over https needs it.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        wget \
        bzip2 \
        build-essential \
        gfortran \
        libopenblas-dev \
        liblapack-dev \
        pkg-config \
        libgeos-dev \
        meson \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L5-L7): download the official PyPy 3.11 binary and
# extract it under /tmp. Upstream publishes sha256s on
# pypy.org/checksums.html; we pin the value via ARG and verify before
# extracting (the TOML's bare `wget` does not verify).
RUN cd /tmp \
    && wget -q -O pypy.tar.bz2 \
        "https://downloads.python.org/pypy/pypy${PYPY_PYTHON_VERSION}-v${PYPY_VERSION}-linux64.tar.bz2" \
    && echo "${PYPY_AMD64_SHA256}  pypy.tar.bz2" | sha256sum -c - \
    && tar -jxf pypy.tar.bz2 \
    && rm pypy.tar.bz2

# TOML install (L8-L9): bootstrap pip inside the freshly extracted
# PyPy and upgrade it.
RUN cd "/tmp/pypy${PYPY_PYTHON_VERSION}-v${PYPY_VERSION}-linux64" \
    && ./bin/pypy3 -m ensurepip \
    && ./bin/pip3 install --upgrade pip

# TOML install (L10): install pinned third-party libraries via the
# bundled pip. `--break-system-packages` mirrors the TOML literally.
# `cppyy==3.5.0` ships as sdist only and downloads its own bundled
# Cling at build time, so this layer is the slow path. `numpy` /
# `scipy` / `scikit-learn` / `pandas` build from sdist when no PyPy
# wheel is published, hence the gfortran / openblas / lapack apt
# deps above. `ac-library-python` is pinned to the same git SHA the
# TOML uses.
RUN cd "/tmp/pypy${PYPY_PYTHON_VERSION}-v${PYPY_VERSION}-linux64" \
    && ./bin/pip3 install --break-system-packages \
        numpy==2.3.2 \
        scipy==1.15.3 \
        networkx==3.5 \
        sympy==1.14.0 \
        sortedcontainers==2.4.0 \
        more-itertools==10.7.0 \
        shapely==2.1.1 \
        bitarray==3.6.0 \
        PuLP==3.2.2 \
        mpmath==1.3.0 \
        pandas==2.3.1 \
        z3-solver==4.15.1.0 \
        scikit-learn==1.7.1 \
        cppyy==3.5.0 \
        acl-cpp-python==0.6.2 \
        "git+https://github.com/not522/ac-library-python@${AC_LIBRARY_PYTHON_REF}"

# TOML install (L11-L13): publish PyPy onto the system PATH by
# copying bin/include/lib into /usr/local/. The TOML keeps the flat
# layout so `pypy3` resolves under /usr/local/bin without symlink
# acrobatics. `/tmp/pypy...` is removed afterwards (the TOML
# comments that the judge wipes /tmp post-install; we mirror the
# end state to keep the image lean).
RUN cd "/tmp/pypy${PYPY_PYTHON_VERSION}-v${PYPY_VERSION}-linux64" \
    && cp -r ./bin/* /usr/local/bin \
    && cp -r ./include/* /usr/local/include \
    && cp -r ./lib/* /usr/local/lib \
    && rm -rf "/tmp/pypy${PYPY_PYTHON_VERSION}-v${PYPY_VERSION}-linux64"

# Smoke test: mirror the TOML compile + execute pipeline. `pypy3 -m
# py_compile` produces `__pycache__/Main.pypy311.pyc` (the TOML's
# `object` path), and the execute command runs Main.py with
# `-X int_max_str_digits=0`.
RUN printf 'print("Hello, PyPy!")\n' > Main.py \
    && pypy3 -m py_compile Main.py \
    && out="$(pypy3 -X int_max_str_digits=0 Main.py)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, PyPy!" \
    && rm -f Main.py \
    && rm -rf __pycache__
