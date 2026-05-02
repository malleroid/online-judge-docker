FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GCC_MAJOR=14

WORKDIR /judge

# TOML install (L1): `sudo apt-get install -y gcc-14`. Ubuntu 24.04
# noble's `gcc-14` package ships GCC 14.2.0, matching the AtCoder
# display string `C23 (GCC 14.2.0)` exactly.
# `libc6-dev` is added beyond the TOML — `gcc-14` only Recommends it,
# so `--no-install-recommends` skips it, and the TOML compile flag
# `-lm` plus crt object files require it at link time.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        "gcc-${GCC_MAJOR}" \
        libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: mirror the TOML compile + execute flow verbatim. The
# program uses C23-only features (`bool` keyword, `nullptr`) so a
# regression where `-std=c23` is dropped would fail the build.
RUN printf '%s\n' \
        '#include <stdio.h>' \
        '#include <math.h>' \
        'int main(void) {' \
        '    bool ok = true;' \
        '    int *p = nullptr;' \
        '    (void)p;' \
        '    printf("%s %g\n", ok ? "Hello, C23!" : "no", sqrt(4.0));' \
        '    return 0;' \
        '}' > Main.c \
    && "gcc-${GCC_MAJOR}" -O2 -march=native -std=c23 -Wall -Wextra -DONLINE_JUDGE -DATCODER Main.c -lm \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && [ "$out" = "Hello, C23! 2" ] \
    && rm -f Main.c a.out
