FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG RUBY_VERSION=3.4.5
ARG RUBY_BUILD_VERSION=20251008
ARG RUBY_BUILD_SHA256=29c1770301efa7114c61e79af05a4c70082c6220d7eecc38feba8e26453ad2a9
ARG AC_LIBTORCH_VERSION=2.8.0
ARG AC_LIBTORCH_SHA256=8dea5bcfed4b53ca0f6852517bea4b4d1f3ff1cc0c21da662e834d34af1ec824

# libtorch 2.8.0 CPU is amd64-only — upstream
# (https://download.pytorch.org/libtorch/cpu/) does not publish an
# aarch64 archive, so the `torch-rb` gem can only build against amd64.
# Build with: docker build --platform linux/amd64
ENV HOME=/root
ENV PATH=/root/.rubies/ruby/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /judge

# TOML install (L314-L315): apt deps. `libreadline6-dev`,
# `libncurses5-dev`, `libgdbm6` are virtual packages on noble — apt
# satisfies them via `libreadline-dev`, `libncurses-dev`, and
# `libgdbm6t64` Provides respectively, so the TOML's literal package
# list installs without modification. `ca-certificates` / `curl` /
# `wget` / `unzip` / `git` are added beyond the TOML — the AtCoder
# judge image carries them implicitly, ubuntu:24.04 minimal does not.
# `git` is needed by some gems' build scripts (notably z3-ruby and
# torch-rb fetch git refs at build time).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        wget \
        autoconf \
        bison \
        patch \
        build-essential \
        rustc \
        libssl-dev \
        libyaml-dev \
        libreadline6-dev \
        zlib1g-dev \
        libgmp-dev \
        libncurses5-dev \
        libffi-dev \
        libgdbm6 \
        libgdbm-dev \
        libdb-dev \
        uuid-dev \
        libz3-dev \
        libgeos-dev \
        libopenblas0 \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L317-L326): fetch and unpack libtorch CPU build into
# /usr/local/{include,lib}, then register its lib path with ldconfig.
# Upstream does not publish a checksum file, so the sha256 is pinned
# via ARG and verified before extraction. The TOML's
# `$HOME/library_version` log is omitted — it is a license-metadata
# breadcrumb, not a runtime artefact.
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

# TOML install (L328-L330): install rbenv/ruby-build. The TOML uses
# the GitHub API to follow `releases/latest`, which would pick
# whatever ruby-build is current at image build time and break
# reproducibility. We pin to v20251008 — the latest release as of
# 2025-10-12, the AtCoder judge environment cutoff — and verify the
# tarball sha256.
RUN cd /tmp \
    && curl -fsSL -o ruby-build.tar.gz \
        "https://github.com/rbenv/ruby-build/archive/refs/tags/v${RUBY_BUILD_VERSION}.tar.gz" \
    && echo "${RUBY_BUILD_SHA256}  ruby-build.tar.gz" | sha256sum -c - \
    && tar xzf ruby-build.tar.gz \
    && PREFIX=/usr/local "/tmp/ruby-build-${RUBY_BUILD_VERSION}/install.sh" \
    && rm -rf /tmp/ruby-build.tar.gz "/tmp/ruby-build-${RUBY_BUILD_VERSION}"

# TOML install (L332): build CRuby 3.4.5 into $HOME/.rubies/ruby via
# ruby-build. ruby-build's 3.4.5 definition pins the upstream Ruby
# tarball (https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.5.tar.gz)
# and verifies sha256 internally, so no separate Ruby checksum ARG is
# needed here.
RUN ruby-build "${RUBY_VERSION}" "${HOME}/.rubies/ruby"

# `rice:4.6.1` is installed beyond the TOML's gem install list. The
# TOML carries `library.rice = { ..., indirect = true }` with no
# version pin, so the resolver naturally picks whatever rice is
# current at build time. AtCoder built the 2025-10 image when rice
# 4.6.1 (2025-06-26) was the latest; rice 4.7.0 (2025-10-23) broke
# the `torch-rb 0.21.0` native extension build with API renames
# ("'Cast' is not a member of 'Rice::detail::Convertible'"). Pinning
# rice to 4.6.1 mirrors the AtCoder-time resolution. It is installed
# in a separate RUN so the next gem install can use `--conservative`
# to keep this exact rice version even though `torch-rb`'s gemspec
# would otherwise pull the latest matching `rice >= 4.5`.
RUN gem install -N rice:4.6.1

# TOML install (L342-L363): install pinned gems. `MAKEFLAGS` must be
# expanded inside the RUN's shell (ENV cannot evaluate `$(nproc)`),
# so it is set inline. `or-tools`, `torch-rb`, `polars-df`, and `z3`
# pull native extensions and are the slow path of this layer.
# `--conservative` makes the resolver reuse the already-installed
# rice 4.6.1 instead of pulling rice 4.12.0 to satisfy torch-rb's
# `>= 4.5` declaration.
RUN export MAKEFLAGS="-j$(nproc)" \
    && gem install -N --conservative \
        ac-library-rb:1.2.0 \
        bit_utils:0.1.2 \
        bitarray:1.3.1 \
        fast_trie:0.5.1 \
        faster_prime:1.0.2 \
        ffi-geos:2.5.0 \
        immutable-ruby:0.2.0 \
        lightgbm:0.4.3 \
        numo-linalg:0.1.7 \
        numo-narray:0.9.2.1 \
        numo-openblas:0.5.1 \
        or-tools:0.16.0 \
        polars-df:0.21.1 \
        rbtree:0.4.6 \
        rgl:0.6.6 \
        rumale:1.0.0 \
        sorted_containers:1.1.0 \
        sorted_set:1.0.3 \
        torch-rb:0.21.0 \
        z3:0.0.20230311

# Smoke test: mirrors the TOML's compile pipeline — `ruby -c` for a
# syntax check, then `ruby --jit Main.rb` to exercise YJIT and stdout.
RUN printf 'puts "Hello, Ruby!"\n' > Main.rb \
    && ruby -c Main.rb \
    && out="$(ruby --jit Main.rb 2>/dev/null)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, Ruby!" \
    && rm -f Main.rb
