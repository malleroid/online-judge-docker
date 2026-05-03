FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG GXX_MAJOR=14

WORKDIR /judge

# TOML install (L1): `sudo apt-get install -y g++-14`. Ubuntu 24.04
# noble's `g++-14` package ships GCC 14.2.0, matching the AtCoder
# display string `C++ IOI-Style(GNU++20) (GCC 14.2.0)` exactly.
# `libc6-dev` is added beyond the TOML — `g++-14` only Recommends it,
# so `--no-install-recommends` skips it, and the TOML compile flag
# `-static` requires crt object files (`crt1.o` etc.) plus `libc.a`,
# both of which come from `libc6-dev`.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        "g++-${GXX_MAJOR}" \
        libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: mirror the TOML compile + execute flow verbatim. The
# program uses C++20-only features (concepts, ranges, <numbers>) so
# any regression dropping `-std=gnu++20` would fail the build. The
# `-static` flag is included so that any missing static-link
# prerequisite surfaces here rather than in production. Note the
# AtCoder macro is `-DEVAL` (IOI-Style convention) and NOT the usual
# `-DONLINE_JUDGE -DATCODER` used by the other C/C++ images.
RUN printf '%s\n' \
        '#include <iostream>' \
        '#include <vector>' \
        '#include <ranges>' \
        '#include <numbers>' \
        '#include <concepts>' \
        'template <std::integral T>' \
        'T sum_squares(const std::vector<T>& v) {' \
        '    T s = 0;' \
        '    for (auto x : v | std::views::transform([](T n){ return n * n; }))' \
        '        s += x;' \
        '    return s;' \
        '}' \
        'int main() {' \
        '    std::vector<int> v{1, 2, 3, 4};' \
        '    std::cout << "sum=" << sum_squares(v) << " pi=" << std::numbers::pi_v<float> << "\n";' \
        '    return 0;' \
        '}' > Main.cpp \
    && "g++-${GXX_MAJOR}" -DEVAL -std=gnu++20 -O2 -pipe -static -s -o a.out Main.cpp \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && case "$out" in 'sum=30 pi=3.14159'*) ;; *) echo "unexpected: $out" >&2; exit 1;; esac \
    && rm -f Main.cpp a.out
