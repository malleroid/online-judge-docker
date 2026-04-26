FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG KUIN_SRC_NAME=kuin_2021_08_17_src_ja
ARG KUIN_ZIP_SHA256=6907b0731409e6288afb06d534a0192717e01372ef955e150f386b968a5c35ca

WORKDIR /judge

# `g++` and `libc6-dev` stay in the runtime image because the TOML
# compile pipeline is two-stage: `kuincl -e cpp` emits a `main.cpp`,
# then `g++ -O2 -o a.out main.cpp` builds the actual executable. Same
# pattern as the eisl image. `unzip` is build-time only.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        g++ \
        libc6-dev \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# The TOML's `wget https://kuina.ch/download/${KUIN_SRC_NAME}.zip`
# permanently 404s — `kuina.ch`'s download page only carries
# `kuin_2021_09_17_ja.zip` (a later revision) and notes the site is
# being rebuilt. The Kuina-chan License (License-13 in the TOML) lets
# us redistribute, so the exact 2021-08-17 source ZIP is vendored
# under `vendor/` (recovered from the Internet Archive
# 2022-11-28 snapshot, sha256 verified). Copying it in beats fetching
# at build time so the image survives independent of either kuina.ch
# or web.archive.org reachability.
COPY vendor/kuin_2021_08_17_src_ja.zip /tmp/kuin.zip

# TOML install step, preserved line-for-line (lines numbered to match
# the `.toml` original):
#   1. KUIN_SRC_NAME=kuin_2021_08_17_src_ja
#   2. wget https://kuina.ch/download/${KUIN_SRC_NAME}.zip
#   3. unzip ${KUIN_SRC_NAME}.zip
#   4. rm ${KUIN_SRC_NAME}.zip
#   5. mv ${KUIN_SRC_NAME} kuin
#   6. cd kuin
#   7. g++ -o kuincl kuin.cpp
#   8. rm -fr sys/{web,exe}
# Only step 2 (the upstream wget) is replaced — the vendored COPY
# above stands in for it. sha256 verification mirrors the integrity
# check the AtCoder build pipeline gets via the upstream URL.
RUN echo "${KUIN_ZIP_SHA256}  /tmp/kuin.zip" | sha256sum -c - \
    && unzip -q /tmp/kuin.zip -d /judge \
    && rm /tmp/kuin.zip \
    && mv /judge/${KUIN_SRC_NAME} /judge/kuin \
    && cd /judge/kuin \
    && g++ -o kuincl kuin.cpp \
    && rm -fr sys/web sys/exe

# Smoke test: reproduce the TOML compile/execute flow end-to-end. The
# Kuin source is the canonical hello shipped under `sys/cpp/_preset00.kn`,
# adapted to print `smoke-ok`. The TOML's compile pipeline runs `kuincl
# -e cpp` (Kuin → C++) and then g++ -O2 against the produced main.cpp.
RUN set -eu; \
    cd /tmp \
    && printf '%s\n' \
        'func main()' \
        '	do cui@print("smoke-ok\n")' \
        'end func' \
        > main.kn \
    && /judge/kuin/kuincl -i main.kn -o main.cpp -s /judge/kuin/sys/ -e cpp -r -q 1>&2 \
    && g++ -O2 -o a.out main.cpp \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f main.kn main.cpp a.out

RUN apt-get purge -y --auto-remove unzip \
    && rm -rf /var/lib/apt/lists/*
