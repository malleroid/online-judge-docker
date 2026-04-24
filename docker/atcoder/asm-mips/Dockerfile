FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils-mips-linux-gnu=2.42-* \
        qemu-user=1:8.2.2+* \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: assemble and run a minimal MIPS O32 program through the TOML's exact
# toolchain (mips-linux-gnu-as + mips-linux-gnu-ld + qemu-mips) to catch toolchain
# breakage at image build time.
RUN cd /tmp \
    && printf '%s\n' \
        '    .text' \
        '    .globl __start' \
        '__start:' \
        '    li   $v0, 4004' \
        '    li   $a0, 1' \
        '    la   $a1, msg' \
        '    li   $a2, 9' \
        '    syscall' \
        '    li   $v0, 4001' \
        '    li   $a0, 0' \
        '    syscall' \
        '    .data' \
        'msg:' \
        '    .ascii "smoke-ok\n"' \
        > Main.s \
    && mips-linux-gnu-as -o Main.o Main.s \
    && mips-linux-gnu-ld -o Main Main.o \
    && out=$(qemu-mips Main) \
    && echo "smoke-test output: $out" \
    && test "$out" = "smoke-ok" \
    && rm -f Main.s Main.o Main
