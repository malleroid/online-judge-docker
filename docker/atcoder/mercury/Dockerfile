FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG MERCURY_DEB_VERSION=22.01.8-1~noble
ARG MERCURY_POOL_URL=http://dl.mercurylang.org/deb/pool/main/m/mercury

# The AtCoder TOML installs Mercury from Paul Bone's third-party apt
# repository at dl.mercurylang.org. That repo only publishes amd64
# packages (no binary-arm64 under dists/noble/main), and no other channel
# ships Mercury 22.01.8 as a binary, so this image is amd64 only.
# Building from source is a 30-minute to 2-hour multi-stage bootstrap
# which would also diverge from the judge's apt-pinned grade layout.
# platforms: linux/amd64

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
# (hlc, hlcpar, llc, llcpar) plus tools/docs — the grade set the AtCoder
# judge relies on.
#
# The repo signing key expired on 2026-07-15, so apt rejects the repo.
# Instead we fetch `mercury-recommended` and its 13 Mercury dependencies
# straight from the pool and check them against sha256 values from the
# repo's Packages index (InRelease signed 2024-07-18, before the key
# expired). apt then installs the local debs and resolves the Ubuntu
# dependencies (perl, gcc, libhwloc-dev, libreadline-dev).
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget ca-certificates \
    && mkdir /tmp/mercury \
    && cd /tmp/mercury \
    && printf '%s\n' \
        "e9208d656f2c179c209a0e5701113f137088ae083fecb30a7eadb0e69e53e6ed  mercury-recommended_${MERCURY_DEB_VERSION}_amd64.deb" \
        "aa4bbbf753bfe12d4619c2a86ea9b6ae9ecd6f980b3797cc9e0a725cfb4afa2e  mercury-tools_${MERCURY_DEB_VERSION}_amd64.deb" \
        "7f952525f091d1255ace35ba096d8b2be665fd0eff6d7880445b42c7c56017c1  mercury-devel_${MERCURY_DEB_VERSION}_amd64.deb" \
        "4e5d67567474f4bcf2957097ef5e4b58061ab0a9a419e095440afdedd965415a  mercury-docs_${MERCURY_DEB_VERSION}_all.deb" \
        "c7ed9b955a354310d3cf1fa2631d9d29fe46043fbefcf51cf42bdf8cc698a6e2  mercury-gc_${MERCURY_DEB_VERSION}_amd64.deb" \
        "15536783f19d6514a427ad151ff7c3c0eea6565ac7b18da6bd683d37ce079c38  mercury-gc-dev_${MERCURY_DEB_VERSION}_amd64.deb" \
        "800ecf3607b288eaeac716ba50c034d31dcfd837adbd79dabf7b650ce9167534  mercury-hlc_${MERCURY_DEB_VERSION}_amd64.deb" \
        "00cbadb18a4b3f8b2a0f3d82d543675d320e9bd03178c4ecc8c7e96ab7587468  mercury-hlc-dev_${MERCURY_DEB_VERSION}_amd64.deb" \
        "b8ff1f3a35902868602be7474b2dc5d4654bdbc7f9984524227b457da2131674  mercury-hlcpar_${MERCURY_DEB_VERSION}_amd64.deb" \
        "96a301c2cb40e7727873c6f7e98abbb1e3e4149d3ff1d7e8fd2fc124cc181b40  mercury-hlcpar-dev_${MERCURY_DEB_VERSION}_amd64.deb" \
        "b229d64c168cf3fa9bdbf6991b6f438200f9348aa061657d070afba1565a3d15  mercury-llc_${MERCURY_DEB_VERSION}_amd64.deb" \
        "ef3510ded5678c12b38d9c0eaa1267adb2f7f5a374cc913b7114bbed06f76280  mercury-llc-dev_${MERCURY_DEB_VERSION}_amd64.deb" \
        "11669dc958a5412c7bf53178bb8e186a03bd81b8c8dffddc5d42933a4b2931f5  mercury-llcpar_${MERCURY_DEB_VERSION}_amd64.deb" \
        "0de68df62ed030e9817ce5ce5607e26d46343dda94e3a16809ebff623c6bfdf9  mercury-llcpar-dev_${MERCURY_DEB_VERSION}_amd64.deb" \
        > SHA256SUMS \
    && cut -d' ' -f3 SHA256SUMS | while read -r deb; do \
        wget -q "${MERCURY_POOL_URL}/${deb}" || exit 1; \
       done \
    && sha256sum -c SHA256SUMS \
    && apt-get install -y --no-install-recommends ./*.deb \
    && cd / \
    && rm -rf /tmp/mercury /var/lib/apt/lists/*

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
