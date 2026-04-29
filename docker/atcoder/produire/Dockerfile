FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG PRODUIRE_VERSION=2.0.1353
ARG PRODUIRE_ZIP_SHA256=7f61230dce0157c760f7cff1258d6f381c8de4b1445f2c9e8543881149022eec
ARG MONO_GPG_KEY=3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

WORKDIR /judge

# `wget` and `unzip` are added beyond the TOML — the AtCoder judge image
# carries them implicitly, ubuntu:24.04 minimal does not. Both are
# build-time only (purged at the end). `ca-certificates` and `gnupg`
# mirror the TOML's first apt step.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        unzip \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line (lines numbered to match
# the `.toml` original):
#   # install mono
#   1.  sudo apt install -y ca-certificates gnupg              (above)
#   2.  sudo gpg --homedir /tmp ... --recv-keys ${MONO_GPG_KEY}
#   3.  echo "deb ... stable-focal main" | sudo tee
#         /etc/apt/sources.list.d/mono-official-stable.list
#   4.  sudo apt update
#   5.  sudo apt install -y mono-devel libgtk2.0-dev
#   # expand produire
#   6.  PRODUIRE_SRC_FILE="produire-mono-${PRODUIRE_VERSION}.zip"
#   7.  wget https://produ.irelang.jp/downloads/mono/${PRODUIRE_SRC_FILE}
#   8.  unzip -O cp932 ${PRODUIRE_SRC_FILE}
#   9.  rm ${PRODUIRE_SRC_FILE}
# `sudo` is dropped (Docker runs as root). `tee` collapses to `>` for
# the same reason. sha256 verification is added between steps 7 and 8
# since upstream does not publish a checksum file. The mono APT repo
# (`download.mono-project.com/repo/ubuntu stable-focal`) is a third-
# party repository (CLAUDE.md tier 5) that we'd normally avoid, but
# the AtCoder TOML hardcodes it and Ubuntu 24.04's stock `mono-runtime`
# (6.8) is a different version from what the judge ships (6.12 from
# stable-focal); deviating from the TOML here would break version
# parity, so we match it. The repo serves both amd64 and arm64.
RUN gpg --homedir /tmp --no-default-keyring \
        --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg \
        --keyserver hkp://keyserver.ubuntu.com:80 \
        --recv-keys "${MONO_GPG_KEY}" \
    && echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" \
        > /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends mono-devel libgtk2.0-dev \
    && PRODUIRE_SRC_FILE="produire-mono-${PRODUIRE_VERSION}.zip" \
    && wget -q "https://produ.irelang.jp/downloads/mono/${PRODUIRE_SRC_FILE}" \
    && echo "${PRODUIRE_ZIP_SHA256}  ${PRODUIRE_SRC_FILE}" | sha256sum -c - \
    && unzip -q -O cp932 "${PRODUIRE_SRC_FILE}" \
    && rm "${PRODUIRE_SRC_FILE}" \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: reproduce the TOML compile + execute flow end-to-end.
# `rdrc.exe` is the Produire compiler; it lowers `Main.rdr` to a .NET
# `Main.exe` that mono then runs. The smoke source prints the literal
# `smoke-ok`.
COPY smoke/Main.rdr produire-mono/Main.rdr
RUN mono produire-mono/rdrc.exe /console /mono /quiet produire-mono/Main.rdr \
    && out="$(mono produire-mono/Main.exe)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f produire-mono/Main.rdr produire-mono/Main.exe

RUN apt-get purge -y --auto-remove gnupg unzip wget \
    && rm -rf /var/lib/apt/lists/*
