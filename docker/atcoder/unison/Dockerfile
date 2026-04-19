FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG UNISON_VERSION=0.5.47
ARG UCM_LINUX_X64_SHA256=462cd865a35d6970a47e21576e5077e1bb6a9aeeb1a37a302a44ae3ab828a48a
ARG UCM_LINUX_ARM64_SHA256=11338c5fe784e01083b2baa4ef398db215ab7ade9902ef39e5fac4f83b97efaa

WORKDIR /judge

# Install runtime deps. ansifilter stays in the final image because the TOML's
# compile step pipes ucm output through it to strip ANSI escapes on failure.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ansifilter \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Install Unison Codebase Manager (ucm) from the upstream GitHub release.
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience.
RUN UCM_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") \
    && UCM_SHA256=$([ "$TARGETARCH" = "arm64" ] && echo "${UCM_LINUX_ARM64_SHA256}" || echo "${UCM_LINUX_X64_SHA256}") \
    && wget -q "https://github.com/unisonweb/unison/releases/download/release/${UNISON_VERSION}/ucm-linux-${UCM_ARCH}.tar.gz" \
        -O /tmp/ucm.tar.gz \
    && echo "${UCM_SHA256}  /tmp/ucm.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/ucm \
    && tar -C /opt/ucm -xf /tmp/ucm.tar.gz \
    && rm /tmp/ucm.tar.gz

# Initialize the codebase at /root/.unison so subsequent ucm invocations have a
# codebase to load into (matches the TOML's `echo project.create | /opt/ucm/ucm`).
RUN echo project.create | /opt/ucm/ucm

# Smoke test: reproduce the TOML compile/execute flow end-to-end. Writes a
# minimal Unison program, drives ucm through load/add/compile, then executes
# the compiled .uc artifact and asserts the expected output.
RUN cd /tmp \
    && printf '%s\n' \
        'main : '"'"'{IO, Exception} ()' \
        'main = do' \
        '  printLine "smoke-ok"' \
        > main.u \
    && sh -c "echo 'load main.u'; sleep 5; echo 'add'" | /opt/ucm/ucm > compile-out \
    && echo 'compile main main' | /opt/ucm/ucm \
    && test -f main.uc \
    && out="$(/opt/ucm/ucm run.compiled main.uc)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -q "smoke-ok" \
    && rm -f main.u main.uc compile-out
