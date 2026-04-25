FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG VALA_VERSION=0.56.18

WORKDIR /judge

# TOML packages plus a few that ubuntu:24.04 minimal lacks but the
# AtCoder judge image already has: `ca-certificates` for the
# gitlab.gnome.org HTTPS clone, `build-essential` (gcc, libc-dev, make)
# for the bootstrap-vala-builds-vala compile, and `pkg-config` so
# autogen.sh can locate the GLib / Gee / GSL pc files. The TOML's
# `valac` 0.56.16 from apt is the bootstrap compiler that the
# self-hosting build needs; it is purged at the end of the install
# (TOML's last `apt autoremove -y valac`).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        autoconf-archive \
        automake \
        bison \
        build-essential \
        ca-certificates \
        flex \
        git \
        gobject-introspection \
        libgee-0.8-dev \
        libgsl-dev \
        libtool \
        pkg-config \
        valac \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1. cd /tmp
#   2. git clone -q https://gitlab.gnome.org/GNOME/vala.git
#   3. cd vala
#   4. git checkout 0.56.18
#   5. git clean -dfx
#   6. ./autogen.sh --disable-valadoc
#   7. make -j $(nproc) && make install
# `make install` lays down /usr/local/bin/valac (0.56.18) and the
# matching libvala / vapi files under /usr/local/. `ldconfig` registers
# /usr/local/lib so the resulting binaries find libvala-0.56.so.0 at
# runtime. `sudo` is dropped because Docker runs as root.
RUN set -eu; \
    cd /tmp \
    && git clone -q https://gitlab.gnome.org/GNOME/vala.git \
    && cd vala \
    && git checkout "${VALA_VERSION}" \
    && git clean -dfx \
    && ./autogen.sh --disable-valadoc \
    && make -j "$(nproc)" \
    && make install \
    && ldconfig

# TOML's terminal install step: remove the bootstrap apt valac so only
# `/usr/local/bin/valac` (0.56.18) remains. Order is load-bearing —
# running this before `make install` would strip the compiler the build
# itself needs.
RUN apt-get update \
    && apt-get --purge autoremove -y valac \
    && rm -rf /var/lib/apt/lists/* /tmp/vala

# Smoke test: reproduce the TOML compile/execute flow. The minimal
# Vala program exercises both `--pkg gee-0.8` (uses Gee.ArrayList) and
# `--pkg gsl` (links against GSL through valac's vapi resolution) so a
# regression in either VAPI lookup surfaces here rather than at judge
# time.
RUN set -eu; \
    cd /tmp \
    && { \
        echo 'using Gee;'; \
        echo ''; \
        echo 'void main() {'; \
        echo '    var list = new ArrayList<string>();'; \
        echo '    list.add ("smoke-ok");'; \
        echo '    foreach (var s in list) {'; \
        echo '        print ("%s\n", s);'; \
        echo '    }'; \
        echo '}'; \
    } > Main.vala \
    && valac --Xcc="-O2" --pkg gee-0.8 --pkg gsl -o a.out Main.vala \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f Main.vala a.out
