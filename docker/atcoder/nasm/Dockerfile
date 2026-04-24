FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

# NASM 2.16.03 produces x86_64 ELF binaries; arm64 hosts cannot execute the output natively.
# Build/run with: docker build --platform linux/amd64 / docker run --platform linux/amd64

ARG NASM_VERSION=2.16.03
ARG NASM_SHA256=1412a1c760bbd05db026b6c0d1657affd6631cd0a63cddb6f73cc6d4aa616148

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
    && wget -q -O nasm.tar.xz "https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz" \
    && echo "${NASM_SHA256}  nasm.tar.xz" | sha256sum -c - \
    && mkdir nasm \
    && tar -C nasm --strip-components=1 -xf nasm.tar.xz \
    && cd nasm \
    && sh configure \
    && make -j"$(nproc)" \
    && make install \
    && cd /tmp \
    && rm -rf nasm nasm.tar.xz

# Smoke test: compile and run a minimal program through the TOML's exact command
# to catch toolchain breakage (nasm + gcc + ld + libc) at image build time.
RUN cd /tmp \
    && printf '%s\n' \
        'global main' \
        'extern puts' \
        'section .data' \
        'msg: db "smoke-ok", 0' \
        'section .text' \
        'main:' \
        '    lea rdi, [rel msg]' \
        '    call puts wrt ..plt' \
        '    xor eax, eax' \
        '    ret' \
        > Main.asm \
    && nasm -f elf64 Main.asm \
    && gcc -o a.out Main.o -lm \
    && ./a.out \
    && rm -f Main.asm Main.o a.out
