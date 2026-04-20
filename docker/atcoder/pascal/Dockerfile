FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

WORKDIR /judge

# Install Free Pascal Compiler 3.2.2 from the Ubuntu 24.04 Universe apt
# repository. Matches the TOML install step literally (`apt install
# fp-compiler-3.2.2`). The versioned package name keeps us on fpc 3.2.2
# regardless of future Ubuntu point releases.
RUN apt-get update \
    && apt-get install -y --no-install-recommends fp-compiler-3.2.2 \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: reproduce the TOML compile/execute flow end-to-end. Pipes the
# compile output through `grep -v` exactly as the TOML does to strip the
# residual "Free Pascal"/"Copyright" banner lines that slip past `-v0`. The
# pipe is wrapped in `|| true` because `grep -v` exits 1 when every input
# line matches the filter (which is the common case here — fpc only prints
# those two lines on success), and AtCoder's `compile` shell runs without
# `set -e`. The `[ -f a.out ]` check replaces the pipeline's missing
# success signal.
RUN set -eu; \
    { \
        echo 'program Main;'; \
        echo 'begin'; \
        echo "  writeln('smoke-ok');"; \
        echo 'end.'; \
    } > Main.p \
    && { fpc -O2 -Sd -Sh -v0 -oa.out Main.p | grep -v -E '^(Free Pascal|Copyright)' 1>&2; } || true \
    && [ -f a.out ] \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f Main.p a.out
