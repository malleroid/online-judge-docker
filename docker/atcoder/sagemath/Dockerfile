FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG SAGE_VERSION=10.7

# `sagemath/sage` 10.7 publishes no prebuilt binaries (the GitHub Release
# `assets` array is empty), and Ubuntu 24.04 noble's apt does not ship a
# `sagemath` core package — only sagemath's database / docs subpackages.
# The TOML's `git clone --depth 1 --branch 10.7` + autotools `make` flow
# is therefore the only path. Multi-arch is technically supported by
# upstream, but the build is hour-scale on amd64 native and would balloon
# under arm64 emulation, so the image is amd64-only.
# Build with: docker build --platform linux/amd64

ENV HOME=/root

WORKDIR /judge

# TOML install (L1-L2): `cd /tmp` + `apt-get update`. The working
# directory shifts to /tmp because the next step git-clones SageMath
# there.
WORKDIR /tmp

# TOML install (L4-L5): apt deps for SageMath's autotools build. The
# TOML lists ~150 packages, mirroring sagemanifolds.obspm.fr's Ubuntu
# install reference (linked in the TOML comment). `--no-install-
# recommends` is intentionally omitted to mirror the TOML literally —
# Sage's build pulls in optional helper tools (texlive bits, mpich,
# etc.) via recommends that the upstream install reference relies on.
# `ca-certificates` is added beyond the TOML — ubuntu:24.04 minimal
# lacks the CA bundle that the AtCoder judge image carries implicitly,
# and `git clone https://...` over TLS needs it.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates \
        automake bc binutils bzip2 cliquer cmake curl ecl \
        eclib-tools fflas-ffpack flintqs g++ gengetopt gfan gfortran git \
        glpk-utils gmp-ecm lcalc libatomic-ops-dev libboost-dev \
        libbraiding-dev libbz2-dev libcdd-dev libcdd-tools libcliquer-dev \
        libcurl4-openssl-dev libec-dev libecm-dev libffi-dev libflint-dev \
        libfreetype-dev libgc-dev libgd-dev libgf2x-dev libgiac-dev \
        libgivaro-dev libglpk-dev libgmp-dev libgsl-dev libhomfly-dev \
        libiml-dev liblfunction-dev liblrcalc-dev liblzma-dev libm4rie-dev \
        libmpc-dev libmpfi-dev libmpfr-dev libncurses-dev libntl-dev \
        libopenblas-dev libpari-dev libpcre3-dev libplanarity-dev libppl-dev \
        libprimesieve-dev libpython3-dev libqhull-dev libreadline-dev \
        librw-dev libsingular4-dev libsqlite3-dev libssl-dev \
        libsuitesparse-dev libsymmetrica2-dev zlib1g-dev libzmq3-dev \
        libzn-poly-dev m4 make nauty openssl palp pari-doc pari-elldata \
        pari-galdata pari-galpol pari-gp2c pari-seadata patch perl pkg-config \
        planarity ppl-dev python3-setuptools python3-venv r-base-dev \
        r-cran-lattice singular sqlite3 sympow tachyon tar tox xcas xz-utils \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L6): shallow clone the SageMath source at tag 10.7.
# `--depth 1` is from the TOML; combined with `--branch ${SAGE_VERSION}`
# this is functionally equivalent to a tag pin (10.7 is immutable).
RUN git clone --branch "${SAGE_VERSION}" --depth 1 https://github.com/sagemath/sage.git

# TOML install (L7-L11): build SageMath from source. `--prefix=$HOME/sage`
# installs into /root/sage; the final `ln -s` exposes the entrypoint at
# /usr/local/bin/sage. `MAKE="make -j$(nproc --all)"` is preserved verbatim
# from the TOML — it sets the parallel level for the recursive sub-make
# the autotools wrapper invokes.
WORKDIR /tmp/sage
RUN make configure
# `--enable-build-as-root` is added beyond the TOML — Sage's
# configure script aborts on root with "You cannot build Sage as
# root" unless this flag is passed. The AtCoder judge image builds
# as a non-root `runner` user, so the TOML omits it; Docker runs
# the build as root, so the flag is necessary.
RUN ./configure --prefix=$HOME/sage --disable-editable --enable-build-as-root
# Outer `make -j1` is added beyond the TOML to serialise SPKG-level
# package installs. Sage's `pari_galdata` and `pari_seadata_small`
# SPKGs both write into `$HOME/sage/share/pari/` independently and
# race on the directory's creation under parallel SPKG dispatch —
# the loser fails with `cp: cannot create directory ...: File
# exists`. Keeping `MAKE="make -j$(nproc --all)"` lets each SPKG's
# internal compile stay parallel, so the total build slowdown is
# limited to the SPKG dispatch dimension.
RUN MAKE="make -j$(nproc --all)" make -j1
RUN ln -s "$HOME/sage/bin/sage" /usr/local/bin/sage

# Smoke test: mirror the TOML's compile + execute pipeline.
# `sage --preparse` lowers Main.sage to Main.sage.py, `py_compile`
# sanity-checks the resulting Python, and `sage --python3` runs it.
WORKDIR /judge
RUN printf 'print("Hello, SageMath!")\n' > Main.sage \
    && sage --preparse Main.sage \
    && python3 -m py_compile Main.sage.py \
    && out="$(sage --python3 Main.sage.py)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, SageMath!" \
    && rm -f Main.sage Main.sage.py
