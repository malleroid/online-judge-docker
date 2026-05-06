FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GCC_MAJOR=15

# AtCoder's judge runs amd64 only. The PPA `puni070/gcc-noble` only
# publishes amd64 binaries — arm64 builds aren't part of its build
# matrix. Build with: docker build --platform linux/amd64

WORKDIR /judge

# TOML install (L35-L38): puni070 PPA + apt deps + gccgo-15.
# `ca-certificates` is added beyond the TOML for `add-apt-repository`
# over HTTPS on the bare ubuntu:24.04 image.
#
# Lessons from the cLay PR (#140) — same PPA, same flake patterns:
#  - The PPA's `apt-get update` is wrapped in a 5-attempt retry loop
#    with 30s backoff. Launchpad has been observed to fail under CI
#    load (and was DDoS'd around 2026-04-30/05-04), and a missing PPA
#    index here would silently fall back to noble's apt (which has no
#    `gccgo-15`), at which point apt's regex-style package matching
#    silently no-ops the install rather than failing.
#  - `--no-install-recommends` is used on the `gccgo-15` install so
#    apt fails fast on a missing package rather than installing
#    unrelated Recommends.
#  - `dpkg -s gccgo-15` verifies the install succeeded; without this,
#    a silent skip would surface only at smoke test time.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        software-properties-common \
    && add-apt-repository -y ppa:puni070/gcc-noble \
    && for i in 1 2 3 4 5; do \
        apt-get update && break ; \
        if [ "$i" = "5" ]; then echo "apt-get update failed after 5 attempts" >&2; exit 1; fi ; \
        echo "apt-get update flaked (attempt $i), retrying in 30s..." >&2 ; \
        sleep 30 ; \
       done \
    && apt-get install -y --no-install-recommends \
        "gccgo-${GCC_MAJOR}" \
        git \
        libgmp-dev \
        binutils-dev \
        libmpfr-dev \
        libmpc-dev \
        libisl-dev \
        libzstd-dev \
        zlib1g-dev \
    && dpkg -s "gccgo-${GCC_MAJOR}" >/dev/null \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L40-L47): module init + go get. Order preserved
# verbatim. The `gccgo-15` apt package ships `/usr/bin/go-15` as the
# wrapper script (Debian/Ubuntu convention for the gccgo Go driver),
# which the TOML invokes directly. Module cache lands at
# `/root/go/pkg/mod` (default `GOMODCACHE`); the user submission's
# `go-15 build` at submission time runs as the same root user from
# the same `/judge` workdir, so the module cache is shared.
RUN "go-${GCC_MAJOR}" mod init atcoder.jp/golang \
    && "go-${GCC_MAJOR}" get \
        github.com/emirpasic/gods \
        gonum.org/v1/gonum \
        github.com/liyue201/gostl \
        github.com/benbjohnson/immutable@v0.3.0 \
        golang.org/x/exp \
        github.com/monkukui/ac-library-go

# Smoke test: TOML compile (L51) + execute (L57). The program uses
# only Go 1.18 language features — gccgo 15.2.0 freezes Go syntax at
# the 1.18 level (no `clear`/`min`/`max` builtins, no `range-over-int`
# / `range-over-func`, no `slices`/`maps` stdlib). The `go.mod` file
# generated above is intentionally preserved for the user submission.
RUN cd /judge \
    && printf '%s\n' \
        'package main' \
        '' \
        'import "fmt"' \
        '' \
        'func main() {' \
        '    fmt.Println("Hello, gccgo!")' \
        '}' > main.go \
    && "go-${GCC_MAJOR}" build -o a.out \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = "Hello, gccgo!" ] \
    && rm -f main.go a.out
