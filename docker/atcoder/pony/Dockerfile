FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG PONYC_VERSION=0.59.0
ARG CORRAL_VERSION=0.9.2

ARG PONYC_SHA256=894b01e75adffb4f29c0fe510b4142a0ffea8278075ecd2676578ae15efedc5d
ARG CORRAL_SHA256=270845acbb0da1c792dbf7782824966b2f96d3390ee12e630bb2b44047e5faec

# ponyc 0.59.0 ships Linux pre-built binaries only for x86_64; the arm64
# Linux asset first appeared in 0.63.0. The TOML pins
# `ponyup default x86_64-linux-ubuntu24.04`, so this image is amd64 only.
# Build with: docker build --platform linux/amd64
#
# The TOML installs ponyc/corral via `ponyup` (Cloudsmith backend). Cloudsmith
# ages out older versions (roughly the last 10 per target), and 0.59.0 has
# already been purged from the ubuntu24.04 channel — `ponyup update ponyc
# release-0.59.0` fails with "requested package was not found". AtCoder's
# judge image was built when 0.59.0 was still on Cloudsmith and froze the
# binaries in place. For fresh rebuilds we have to bypass ponyup and pull
# the same upstream tarballs directly from GitHub Release (where historical
# versions are retained indefinitely). The binaries delivered by both paths
# are identical; only the fetch mechanism differs.

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/ponyc.tar.gz \
        "https://github.com/ponylang/ponyc/releases/download/${PONYC_VERSION}/ponyc-x86-64-unknown-linux-ubuntu24.04.tar.gz" \
    && echo "${PONYC_SHA256}  /tmp/ponyc.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/ponyc \
    && tar -C /opt/ponyc --strip-components=1 -xf /tmp/ponyc.tar.gz \
    && ln -s /opt/ponyc/bin/ponyc /usr/local/bin/ponyc \
    && rm /tmp/ponyc.tar.gz

RUN curl -fsSL -o /tmp/corral.tar.gz \
        "https://github.com/ponylang/corral/releases/download/${CORRAL_VERSION}/corral-x86-64-unknown-linux.tar.gz" \
    && echo "${CORRAL_SHA256}  /tmp/corral.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/corral \
    && tar -C /opt/corral --strip-components=1 -xf /tmp/corral.tar.gz \
    && ln -s /opt/corral/bin/corral /usr/local/bin/corral \
    && rm /tmp/corral.tar.gz

# TOML-driven project setup: initialise a corral project and pull the two
# library deps the AtCoder install step adds (regex + valbytes). The TOML
# derives each version at install time via `gh_latest_version` (GitHub API
# /releases/latest); we preserve that lookup verbatim so the resolved
# versions track whatever was latest at Docker build time, matching the
# non-determinism of AtCoder's own install workflow.
RUN set -eu; \
    corral init; \
    gh_latest_version() { \
        info="$(curl -s https://api.github.com/repos/"$1"/"$2"/releases/latest)"; \
        echo "$info" | sed -n '/tag_name/ { s/.*: "v\?\(.*\)".*/\1/;p }'; \
    }; \
    AC_REGEX_VERSION="$(gh_latest_version ponylang regex)"; \
    corral add --version="$AC_REGEX_VERSION" github.com/ponylang/regex.git; \
    AC_VALBYTES_VERSION="$(gh_latest_version ponylang valbytes)"; \
    corral add --version="$AC_VALBYTES_VERSION" github.com/ponylang/valbytes.git; \
    corral update

# Smoke test: reproduce the TOML compile/execute flow end-to-end. The TOML
# wraps ponyc in `corral run --` so deps from corral.json are resolved into
# the module path. `-V=0` silences the version banner; on failure the TOML
# trims `err-out` via `tail -n +4` to drop the "Building" header before
# routing to stderr.
RUN set -eu; \
    printf '%s\n' \
        'actor Main' \
        '  new create(env: Env) =>' \
        '    env.out.print("smoke-ok")' \
        > Main.pony \
    && if ! corral run -- ponyc -b a.out -V=0 > err-out; then \
           tail -n +4 err-out 1>&2; exit 1; \
       fi \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f Main.pony a.out err-out
