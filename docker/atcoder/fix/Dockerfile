FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG FIX_VERSION=v1.1.0-alpha.12
ARG FIX_SHA256=b3e96ecd22e0b8356fd2dbf71254adcd831de51eee0b4913d228fd7735f9354b

# Fix v1.1.0-alpha.12 only ships an x86_64-unknown-linux-gnu prebuilt
# binary; no aarch64 Linux release asset exists upstream. AtCoder's
# judge runs on amd64.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# `libgmp-dev` is the apt dep the TOML pulls (the gmp-fix crate links
# against -lgmp at build time). `build-essential` is added beyond the
# TOML — `fix build` shells out to both `cc` (for C interop type
# probes like `.fixlang/check_c_types.*.c`) and `make` (to build
# crate object files via `make -s lib.o`); without them the build
# aborts with `No such file or directory`. The AtCoder judge image
# provides them implicitly; ubuntu:24.04 minimal does not. The whole
# toolchain stays in the runtime image. `wget` + `ca-certificates`
# mirror the TOML's fetch step (purged after install).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        libgmp-dev \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1.  AC2025_FIX_VERSION=v1.1.0-alpha.12               (Docker ARG)
#   2.  apt-get update / install libgmp-dev              (above)
#   3.  cd /tmp
#   4.  wget https://.../fix-v1.1.0-alpha.12-x86_64-unknown-linux-gnu
#   5.  install fix /usr/local/bin/fix
#   6.  fix init
#   7.  fix deps add character@=1.0.1 ... minilib-xml@=0.5.1   (25 crates)
#   8.  cat << EOF > main.fix                            (COPY below)
#   9.  fix build -O none                                (smoke type-check
#                                                         cache + run)
#   10. ./a.out
#   11. rm a.out
#   12. rm -rf .fixlang/intermediate
# `sudo` is dropped because Docker runs as root. sha256 verification
# is added since upstream does not publish a checksum file.
RUN cd /tmp \
    && wget -q -O fix \
        "https://github.com/tttmmmyyyy/fixlang/releases/download/${FIX_VERSION}/fix-${FIX_VERSION}-x86_64-unknown-linux-gnu" \
    && echo "${FIX_SHA256}  fix" | sha256sum -c - \
    && install fix /usr/local/bin/fix \
    && rm fix

# `fix init` creates `fixproj.toml` and a project skeleton under
# /judge; `fix deps add` then materialises every crate the AtCoder
# judge exposes (CPLib competitive-programming bundle + Fix's minilib
# suite + gmp-fix). Versions are pinned with `=X.Y.Z` exactly as the
# TOML lists them. The registry fetch happens once here and is
# committed into the image so judge-time `fix build` runs offline.
RUN cd /judge \
    && fix init \
    && fix deps add \
        character@=1.0.1 \
        hash@=1.1.0 \
        hashmap@=1.1.3 \
        hashset@=1.1.1 \
        math@=1.2.0 \
        random@=1.1.1 \
        regexp@=1.1.1 \
        time@=1.0.2 \
        binary-heap@=0.1.2 \
        bool-array@=0.1.1 \
        cp-library@=0.6.6 \
        ring-buffer@=0.1.1 \
        gmp-fix@=0.6.0 \
        minilib-common@=0.6.1 \
        minilib-text@=0.5.2 \
        minilib-binary@=0.5.1 \
        minilib-collection@=0.6.0 \
        minilib-monad@=0.6.0 \
        minilib-comonad@=0.5.1 \
        minilib-random@=0.5.2 \
        minilib-math@=0.6.1 \
        minilib-crypto@=0.5.1 \
        minilib-app@=0.5.1 \
        minilib-json@=0.5.1 \
        minilib-xml@=0.5.1

# Smoke test mirrors the TOML's terminal install steps: write the
# canonical `main.fix` (verbatim from the TOML — references every
# CPLib symbol so the type-check cache is generated for the full
# library surface), build with `-O none` to populate `.fixlang/`
# without the full LLVM optimisation passes, run `./a.out` to
# confirm the runtime, then strip `a.out` and `.fixlang/intermediate`
# so the image only carries the fetched deps and the type-check
# cache (matches what the TOML leaves behind for the judge).
# `main.fix` is intentionally kept (the TOML keeps it too); the
# judge run replaces it with the submitted source.
COPY main.fix /judge/main.fix
RUN cd /judge \
    && fix build -O none \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, Fix!" \
    && rm -f a.out \
    && rm -rf .fixlang/intermediate

RUN apt-get purge -y --auto-remove wget \
    && rm -rf /var/lib/apt/lists/*
