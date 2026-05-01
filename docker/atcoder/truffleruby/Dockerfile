FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG AC_GRAAL_VERSION=25.0.0
ARG AC_TRUFFLERUBY_SHA256=fc8896c38f15217c004089bc3bfff1575767a6356b6a05b842bf6284e2e52788
ARG AC_LIBTORCH_VERSION=2.8.0
ARG AC_LIBTORCH_SHA256=8dea5bcfed4b53ca0f6852517bea4b4d1f3ff1cc0c21da662e834d34af1ec824

# libtorch 2.8.0 CPU is amd64-only — upstream
# (https://download.pytorch.org/libtorch/cpu/) does not publish an
# aarch64 archive, so the `torch-rb` gem can only build against amd64.
# Build with: docker build --platform linux/amd64
ENV HOME=/root
ENV PATH=/root/.rubies/truffleruby/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /judge

# TOML install (L235-L236): apt deps. The TOML lists only the runtime
# libs the gems link against; ubuntu:24.04 minimal lacks the
# fetch/build chain (`ca-certificates`, `curl`, `git`, `unzip`,
# `wget`, `build-essential`) that the AtCoder judge image carries
# implicitly, so they are added beyond the TOML. `build-essential`
# is required by truffleruby's `post_install_hook.sh`, which
# recompiles the OpenSSL and Psych C extensions against the system
# libssl/libyaml. `libgmp-dev` and `libffi-dev` are added for the
# z3 / ffi-geos gem build paths.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        wget \
        build-essential \
        libssl-dev \
        libyaml-dev \
        zlib1g-dev \
        libz3-dev \
        libgeos-dev \
        libgmp-dev \
        libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L238-L243): fetch the TruffleRuby Native standalone
# (Oracle GraalVM Free Terms and Conditions License — `!License-28`
# in the TOML), extract under `$HOME/.rubies/truffleruby`, then run
# `post_install_hook.sh` so the bundled OpenSSL/Psych C extensions
# rebuild against the system libssl/libyaml. The TOML's `export
# PATH=...` line is replaced by the Dockerfile-level `ENV PATH=...`
# above so PATH persists across layers. Upstream does not publish a
# checksum file, so the sha256 is pinned via ARG and verified before
# extraction.
RUN cd /tmp \
    && wget -q -O truffleruby.tar.gz \
        "https://github.com/oracle/truffleruby/releases/download/graal-${AC_GRAAL_VERSION}/truffleruby-${AC_GRAAL_VERSION}-linux-amd64.tar.gz" \
    && echo "${AC_TRUFFLERUBY_SHA256}  truffleruby.tar.gz" | sha256sum -c - \
    && mkdir -p "${HOME}/.rubies/truffleruby" \
    && tar -C "${HOME}/.rubies/truffleruby" --strip-components=1 -xf truffleruby.tar.gz \
    && "${HOME}/.rubies/truffleruby/lib/truffle/post_install_hook.sh" \
    && rm -f /tmp/truffleruby.tar.gz

# TOML install (L245-L253): fetch and unpack libtorch CPU build into
# /usr/local/{include,lib}, then register its lib path with ldconfig.
# Upstream does not publish a checksum file; the sha256 is pinned
# via ARG (same value as the CRuby Ruby image) and verified before
# extraction. The TOML's `$HOME/library_version` log is omitted — it
# is a license-metadata breadcrumb, not a runtime artefact.
RUN cd /tmp \
    && wget -q -O libtorch.zip \
        "https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-${AC_LIBTORCH_VERSION}%2Bcpu.zip" \
    && echo "${AC_LIBTORCH_SHA256}  libtorch.zip" | sha256sum -c - \
    && unzip -q libtorch.zip \
    && cp -dR libtorch/include /usr/local/ \
    && cp -dR libtorch/lib /usr/local/ \
    && echo /usr/local/lib > /etc/ld.so.conf.d/libtorch.conf \
    && ldconfig \
    && rm -rf /tmp/libtorch /tmp/libtorch.zip

# TOML install (L261-L266): write the runtime wrapper that converts
# the judge's `{memory:mb}` argument into TruffleRuby's `--vm.Xmx` /
# `--vm.Xss` flags. The execution config (`sh ruby.sh {memory:mb}`)
# resolves the script relative to cwd, so it lives at /judge/ruby.sh.
RUN cat <<'EOF' > /judge/ruby.sh
#! /bin/sh
stack_size=$(($1 * 25 / 100))
heap_size=$(($1 * 90 / 100))
ruby --vm.Xmx"$heap_size"M --vm.Xss"$stack_size"M Main.rb
EOF

# `rice:4.6.1` is installed beyond the TOML's gem install list. The
# gem resolver picks whichever rice satisfies torch-rb's `>= 4.5`
# declaration at build time; rice 4.7.0 (2025-10-23) renamed
# `Rice::detail::Convertible::Cast` and broke the `torch-rb 0.21.0`
# native extension build. AtCoder built the 2025-10 image when rice
# 4.6.1 (2025-06-26) was the latest; pinning rice to 4.6.1 mirrors
# that resolution. Same fix as the CRuby Ruby image (see
# `docker/atcoder/ruby/Dockerfile`); the second `gem install` uses
# `--conservative` so torch-rb reuses 4.6.1 instead of pulling
# rice 4.12.0.
RUN gem install -N rice:4.6.1

# TOML install (L269-L284): install pinned gems. `MAKEFLAGS` must be
# expanded inside the RUN's shell (ENV cannot evaluate `$(nproc)`),
# so it is set inline. `or-tools`, `torch-rb`, `lightgbm`, `z3`, and
# `ffi-geos` build native extensions through Sulong (TruffleRuby's
# LLVM bitcode runtime) and are the slow path of this layer.
# `--conservative` keeps the rice 4.6.1 installed above instead of
# pulling rice 4.12.0 to satisfy torch-rb's `>= 4.5` declaration.
RUN export MAKEFLAGS="-j$(nproc)" \
    && gem install -N --conservative \
        ac-library-rb:1.2.0 \
        bit_utils:0.1.2 \
        bitarray:1.3.1 \
        faster_prime:1.0.2 \
        ffi-geos:2.5.0 \
        immutable-ruby:0.2.0 \
        lightgbm:0.4.3 \
        or-tools:0.16.0 \
        rbtree:0.4.6 \
        rgl:0.6.6 \
        sorted_containers:1.1.0 \
        sorted_set:1.0.3 \
        torch-rb:0.21.0 \
        z3:0.0.20230311

# Smoke test: mirror the TOML's compile + execute pipeline — `ruby
# -c` for a syntax check, then run via the wrapper script with a
# 256 MB memory budget.
RUN printf 'puts "Hello, TruffleRuby!"\n' > Main.rb \
    && ruby -c Main.rb \
    && out="$(sh ruby.sh 256 2>/dev/null)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, TruffleRuby!" \
    && rm -f Main.rb
