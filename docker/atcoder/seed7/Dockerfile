FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG SEED7_RELEASE=05_20250729
ARG SEED7_SHA256=416a8a54e61b1539f5fbc131827a38d588758415e617b9941af3cd6b0e2105f0

WORKDIR /judge

# gcc / libc6-dev / libncurses-dev / libx11-dev remain in the final image because
# s7c invokes gcc at compile time and links against ncurses and X11.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        libc6-dev \
        libncurses-dev \
        libx11-dev \
        make \
    && rm -rf /var/lib/apt/lists/*

# Build Seed7 from the upstream SourceForge tarball. The absolute paths of the
# Seed7 library (S7_LIB_DIR / SEED7_LIBRARY) are baked into s7c at build time
# (via chkccomp during `make depend`), so /opt/seed7 must stay in place after
# install. `make install` only creates symlinks into /usr/local/bin.
RUN curl -fsSL -o /tmp/seed7.tgz \
        "https://downloads.sourceforge.net/project/seed7/seed7/seed7_${SEED7_RELEASE}/seed7_${SEED7_RELEASE}.tgz" \
    && echo "${SEED7_SHA256}  /tmp/seed7.tgz" | sha256sum -c - \
    && tar -C /opt -xzf /tmp/seed7.tgz \
    && cd /opt/seed7/src \
    && make depend \
    && make -j "$(nproc)" \
    && make -j "$(nproc)" s7c \
    && make install \
    && rm /tmp/seed7.tgz

# Smoke test: compile and run a minimal Seed7 program through the TOML's exact
# toolchain (s7c -O2 -oc3 Main.sd7 && ./Main) to catch toolchain breakage at
# image build time.
RUN cd /tmp \
    && printf '%s\n' \
        '$ include "seed7_05.s7i";' \
        '' \
        'const proc: main is func' \
        '  begin' \
        '    writeln("smoke-ok");' \
        '  end func;' \
        > Main.sd7 \
    && s7c -O2 -oc3 Main.sd7 \
    && out="$(./Main)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f Main.sd7 Main Main.c

# Purge build-only deps. gcc / libc6-dev / libncurses-dev / libx11-dev stay
# because s7c invokes them to compile generated C code.
RUN apt-get purge -y --auto-remove curl make \
    && rm -rf /var/lib/apt/lists/*
