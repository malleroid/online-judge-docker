FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG APL_VERSION=1.9
ARG APL_SHA256=291867f1b1937693abb57be7d9a37618b0376e3e2709574854a7bbe52bb28eb8

WORKDIR /judge

# `wget` and `ca-certificates` are added beyond the TOML — the AtCoder
# judge image ships them implicitly; ubuntu:24.04 minimal does not, and
# the TOML's bare `wget` over https needs both.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1.  sudo apt update                                      (above)
#   2.  cd /tmp
#   3.  wget https://ftpmirror.gnu.org/gnu/apl/apl-1.9.tar.gz
#   4.  tar xzf apl-1.9.tar.gz
#   5.  cd apl-1.9
#   6.  sudo apt install -y g++ subversion make
#   7.  sudo apt install -y libfftw3-dev
#   8.  ./configure
#   9.  make
#   10. sudo make install
# `sudo` is dropped (Docker runs as root). The TOML uses
# `ftpmirror.gnu.org` (an HTTP redirector) for the wget; the Dockerfile
# pins to `ftp.gnu.org` directly for reproducibility, and adds sha256
# verification (the TOML does not verify). The two `apt install` calls
# stay split into two RUN layers to mirror the TOML's separation.
RUN cd /tmp \
    && wget -q -O "apl-${APL_VERSION}.tar.gz" \
        "https://ftp.gnu.org/gnu/apl/apl-${APL_VERSION}.tar.gz" \
    && echo "${APL_SHA256}  apl-${APL_VERSION}.tar.gz" | sha256sum -c - \
    && tar xzf "apl-${APL_VERSION}.tar.gz" \
    && rm "apl-${APL_VERSION}.tar.gz"

RUN apt-get update \
    && apt-get install -y --no-install-recommends g++ subversion make \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends libfftw3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cd "/tmp/apl-${APL_VERSION}" \
    && ./configure \
    && make \
    && make install \
    && cd / \
    && rm -rf "/tmp/apl-${APL_VERSION}"

# Smoke test: mirror the TOML execution config — `apl -f Main.apl` with
# the same flag set. `⎕←` writes to stdout from the script.
RUN printf "⎕←'Hello, APL!'\n" > Main.apl \
    && out="$(apl --silent --noCIN --noCONT --noColor --OFF --noSV --rawCIN -f Main.apl)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, APL!" \
    && rm -f Main.apl
