FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG MERCURY_DEB_VERSION=22.01.8-1~noble

# The AtCoder TOML installs Mercury from Paul Bone's third-party apt
# repository at dl.mercurylang.org. That repo only publishes amd64
# packages (no binary-arm64 under dists/noble/main), and no other channel
# ships Mercury 22.01.8 as a binary, so this image is amd64 only.
# Building from source is a 30-minute to 2-hour multi-stage bootstrap
# which would also diverge from the judge's apt-pinned grade layout.
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# TOML install step, preserved line-for-line (steps numbered to match
# the `.toml` original):
#   1. sudo apt update
#   2. sudo apt-get install -y wget ca-certificates
#   3. cd /tmp
#   4. wget https://paul.bone.id.au/paul.asc
#   5. sudo cp paul.asc /etc/apt/trusted.gpg.d/paulbone.asc
#   6-7. echo "deb[-src] http://dl.mercurylang.org/deb/ noble main"
#        | sudo tee /etc/apt/sources.list.d/mercury.list
#   8. sudo apt update
#   9. sudo apt-get install -y mercury-recommended
# `mercury-recommended` pulls the four officially supported grades
# (hlc, hlcpar, llc, llcpar) plus tools/docs/examples — the grade set
# the AtCoder judge relies on. The deb version is pinned so a future
# `~noble` packaging revision does not shift our image out from under
# the TOML.
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget ca-certificates \
    && cd /tmp \
    && wget -q https://paul.bone.id.au/paul.asc \
    && cp paul.asc /etc/apt/trusted.gpg.d/paulbone.asc \
    && rm paul.asc \
    && echo "deb http://dl.mercurylang.org/deb/ noble main" > /etc/apt/sources.list.d/mercury.list \
    && echo "deb-src http://dl.mercurylang.org/deb/ noble main" >> /etc/apt/sources.list.d/mercury.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends "mercury-recommended=${MERCURY_DEB_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: reproduce the TOML compile/execute flow end-to-end. Writes
# the canonical Mercury hello module, runs the TOML's exact
# `mmc -o a.out -O 5 main` invocation, executes a.out and asserts the
# expected output.
RUN set -eu; \
    { \
        echo ':- module main.'; \
        echo ':- interface.'; \
        echo ':- import_module io.'; \
        echo ':- pred main(io::di, io::uo) is det.'; \
        echo ':- implementation.'; \
        echo 'main(!IO) :- io.write_string("smoke-ok\n", !IO).'; \
    } > main.m \
    && mmc -o a.out -O 5 main \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f main.m a.out main.mh main.c main.o Mercury -r 2>/dev/null || true \
    && rm -rf Mercury
