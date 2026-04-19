FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

WORKDIR /judge

# Install build dependencies
# - build-essential: cc to compile tbc.c and the generated a.c
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# TBC 1.0 source (tbc.c + core.int) is vendored in this directory.
# Upstream is a fragile CMU student homepage (2003 frozen, HTTP only, no GitHub mirror).
# The TBC license explicitly permits redistribution. Divergence from TOML is intentional.
COPY tbc.c /tmp/tbc.c
COPY core.int /judge/core.int

# Build and install the tbc compiler
RUN cc /tmp/tbc.c -o /bin/tbc \
    && rm /tmp/tbc.c

# Smoke test: exercise TOML's exact compile/execute flow (tbc -> cc -O2 -w -> a.out).
# The program `"A",@` pushes 'A' (65) via stringmode, outputs it with `,`, and halts with `@`.
RUN cd /judge \
    && printf '%s' '"A",@' > Main.bf \
    && tbc Main.bf > a.c \
    && cc -O2 -w a.c -o a.out \
    && OUT=$(./a.out) \
    && echo "smoke test output: ${OUT}" \
    && [ "${OUT}" = "A" ] \
    && rm Main.bf a.c a.out
