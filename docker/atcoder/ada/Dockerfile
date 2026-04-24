FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG GNAT_VERSION=15
ARG ALR_VERSION=2.1.0
ARG ALR_SHA256=e3b32cb0afe981b23d1a68da77452cf81ee1d82de8ebaf01c5e233be8b463fbe
ARG GPRBUILD_VERSION=25.0.1

# Pinning gnatcoll / gnatcoll_gmp to ^25.0.0 matches the AtCoder 2025-10
# snapshot. gnatcoll 26.0.0 (released after the judge env was built) split
# gnatcoll_minimal out, moved `gnatcoll.gpr` under `core/gnatcoll_core.gpr`,
# and dropped the libgpr dependency that the TOML's timeval patch targets.
# Without pinning, `alr with gnatcoll` pulls 26.0.0 and `with "gnatcoll";`
# in main.gpr fails with "imported project file not found".
ARG GNATCOLL_CONSTRAINT=^25.0.0
ARG GNATCOLL_GMP_CONSTRAINT=^25.0.0

# Alire publishes `alr` as an x86_64-only Linux binary, and the AtCoder TOML
# sources gnat-15 from a PPA (puni070/gcc-noble) that only builds for amd64.
# Build with: docker build --platform linux/amd64

ENV HOME=/root

WORKDIR /judge

# Install GNAT 15 from the puni070/gcc-noble PPA (same source as the AtCoder
# judge) plus the libraries required to build gnatcoll / gnatcoll_gmp.
# xz-utils and unzip are needed to extract the alr zip and the gprbuild
# debian.tar.xz bundle. patch applies the libgpr timeval diff taken from that
# bundle. curl queries the Launchpad API for the latest gprbuild Debian
# packaging revision (matches the TOML install step).
RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:puni070/gcc-noble \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnat-${GNAT_VERSION} \
        libgmp-dev \
        libisl-dev \
        libmpc-dev \
        libmpfr-dev \
        libzstd-dev \
        patch \
        unzip \
        wget \
        xz-utils \
        zlib1g-dev \
    && apt-get --purge -y autoremove gcc \
    && rm -rf /var/lib/apt/lists/*

# Mirror the TOML's do_update_alternatives helper: register every
# `/usr/bin/*-${GNAT_VERSION}` binary pulled in by gnat-15 as an alternative
# so `gnat`, `gnatbind`, `gnatlink`, `gnatmake`, etc. all resolve to the
# gnat-15 toolchain. This is what lets `alr toolchain --select gnat_external`
# find a usable compiler on PATH.
RUN set -eu; \
    slaves=""; \
    packages="$(apt-cache depends --recurse --installed gnat-${GNAT_VERSION} \
        | grep -E "^[A-z].*-${GNAT_VERSION}.*" | sort -u)"; \
    for bin in $(dpkg -L $packages | grep -E "^/usr/bin/.*-${GNAT_VERSION}$"); do \
        name="$(basename "$bin" | sed "s/-${GNAT_VERSION}$//")"; \
        if [ "$name" != "gnat" ]; then \
            slaves="$slaves --slave /usr/bin/$name $name /usr/bin/$name-${GNAT_VERSION}"; \
        fi; \
    done; \
    update-alternatives --quiet --install /usr/bin/gnat gnat \
        /usr/bin/gnat-${GNAT_VERSION} 100 $slaves

# Install Alire. The upstream zip contains `bin/alr` and `LICENSE.txt`; we
# extract only the binary straight into /usr/local (same invocation as the
# AtCoder TOML: `unzip alr.zip -d /usr/local bin/alr`).
RUN wget -q -O /tmp/alr.zip \
        "https://github.com/alire-project/alire/releases/download/v${ALR_VERSION}/alr-${ALR_VERSION}-bin-x86_64-linux.zip" \
    && echo "${ALR_SHA256}  /tmp/alr.zip" | sha256sum -c - \
    && unzip -o /tmp/alr.zip -d /usr/local bin/alr \
    && chmod +x /usr/local/bin/alr \
    && rm /tmp/alr.zip

# Select the pinned gprbuild toolchain first, then download the matching
# Debian source packaging from Launchpad plucky so we can pull the
# adapt-to-private-timeval.diff patch out of it. The patch is applied below
# once `alr with` has populated the libgpr crate under $HOME/.local/share.
# Finally, select gnat_external so Alire uses the gnat-15 we registered via
# update-alternatives above instead of trying to fetch its own gnat_native.
RUN cd /tmp \
    && alr -n --force toolchain --select gprbuild=${GPRBUILD_VERSION} \
    && gprbuild_latest_version="$(curl -sS \
        'https://api.launchpad.net/1.0/ubuntu/+archive/primary?ws.op=getPublishedSources&source_name=gprbuild&exact_match=true&distro_series=https://api.launchpad.net/1.0/ubuntu/plucky' \
        | sed 's/,/\n/g' | grep -m 1 version | awk '{ print $2 }' | sed 's/"//g')" \
    && wget -q -O /tmp/gprbuild.tar.xz \
        "https://launchpad.net/ubuntu/+archive/primary/+files/gprbuild_${gprbuild_latest_version}.debian.tar.xz" \
    && tar -C /tmp -xf /tmp/gprbuild.tar.xz \
    && alr -n --force toolchain --select gnat_external

# Create the Alire project skeleton in /judge. The order follows the TOML
# install step exactly: write alire.toml, add each crate with `alr with`
# (appending `with "...";` to main.gpr), run `alr -n update`, apply the
# libgpr timeval patch, then append the project body. The libgpr loop
# iterates both release checkouts and per-build workspaces; Alire
# materialises the same crate in two places and gprbuild reads from both.
RUN set -eu; \
    { \
        printf '%s\n' 'name = "main"'; \
        printf '%s\n' 'description = ""'; \
        printf '%s\n' 'version = "0.1.0"'; \
    } > alire.toml \
    && for library in bit_sets euler_tools "gnatcoll${GNATCOLL_CONSTRAINT}" "gnatcoll_gmp${GNATCOLL_GMP_CONSTRAINT}" hungarian; do \
        alr -n with "$library"; \
        name="${library%%[=^~]*}"; \
        printf 'with "%s";\n' "$name" >> main.gpr; \
    done \
    && alr -n update \
    && for dir in "$HOME"/.local/share/alire/releases/libgpr_*; do \
        (cd "$dir" && patch -p1 < /tmp/debian/patches/adapt-to-private-timeval.diff); \
    done \
    && for dir in "$HOME"/.local/share/alire/builds/libgpr_*/*; do \
        (cd "$dir" && patch -p1 < /tmp/debian/patches/adapt-to-private-timeval.diff); \
    done \
    && { \
        printf '%s\n' 'project Main is'; \
        printf '%s\n' '   for Source_Dirs use ("src");'; \
        printf '%s\n' '   for Object_Dir  use "obj";'; \
        printf '%s\n' '   for Main use ("main.adb");'; \
        printf '%s\n' '   package Compiler is'; \
        printf '%s\n' '     for Default_Switches ("Ada") use ("-gnat2022", "-O2");'; \
        printf '%s\n' '   end Compiler;'; \
        printf '%s\n' 'end Main;'; \
    } >> main.gpr

# Smoke test: reproduce the TOML compile/execute flow end-to-end. The source
# multiplies two large integers through gnatcoll_gmp (the heaviest crate to
# link) and prints a recognisable token when the product is non-zero. If any
# of gprbuild, the libgpr patch, the gnat_external selection, or the GMP
# linkage regress, this step fails at image build time rather than at judge
# time.
RUN set -eu; \
    mkdir -p src; \
    { \
        printf '%s\n' 'with GNATCOLL.GMP.Integers; use GNATCOLL.GMP.Integers;'; \
        printf '%s\n' 'with Ada.Text_IO;           use Ada.Text_IO;'; \
        printf '\n'; \
        printf '%s\n' 'procedure Main is'; \
        printf '%s\n' '   A, B, Zero : Big_Integer;'; \
        printf '%s\n' 'begin'; \
        printf '%s\n' '   Set (A,    "999999999999", 10);'; \
        printf '%s\n' '   Set (B,    "999999999999", 10);'; \
        printf '%s\n' '   Set (Zero, "0",            10);'; \
        printf '%s\n' '   if (A * B) /= Zero then'; \
        printf '%s\n' '      Put_Line ("smoke-ok");'; \
        printf '%s\n' '   else'; \
        printf '%s\n' '      Put_Line ("smoke-fail");'; \
        printf '%s\n' '   end if;'; \
        printf '%s\n' 'end Main;'; \
    } > src/main.adb \
    && alr --no-color --no-tty build > /dev/null \
    && out="$(./obj/main)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f obj/main

# Purge fetch-only deps. ca-certificates stays for any runtime TLS use;
# patch/unzip/xz-utils are no longer needed once the libgpr diff has been
# applied and the alr zip is gone.
RUN apt-get purge -y --auto-remove curl patch unzip wget xz-utils \
    && rm -rf /var/lib/apt/lists/* /tmp/debian /tmp/gprbuild.tar.xz
