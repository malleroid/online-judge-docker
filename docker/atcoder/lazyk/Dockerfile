FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG LAZYK_VERSION=1.0.0
ARG LAZYK_SHA256=c57edaab448f84eda2c98411e0fb4192e36113df49461db9285a62ca1f613d42

WORKDIR /judge

# Install build dependencies.
# - build-essential: gcc + make to build lazyk from source (TOML uses gcc + make; build-essential is the project pattern)
# - ca-certificates: HTTPS for tarball fetch
# - curl: project-standard for downloading release tarballs
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Fetch, verify, build, and install lazyk (irori v1.0.0).
# Pure C99, no arch-specific code, so builds cleanly on amd64/arm64.
RUN curl -fsSL -o /tmp/lazyk.tar.gz \
        "https://github.com/irori/lazyk/archive/refs/tags/v${LAZYK_VERSION}.tar.gz" \
    && echo "${LAZYK_SHA256}  /tmp/lazyk.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/lazyk.tar.gz -C /tmp \
    && make -C /tmp/lazyk-${LAZYK_VERSION} \
    && make -C /tmp/lazyk-${LAZYK_VERSION} install \
    && rm -rf /tmp/lazyk.tar.gz /tmp/lazyk-${LAZYK_VERSION}

# Smoke test: verify the TOML execute flow end-to-end with the identity combinator 'I',
# which behaves as an echo program. Piping 'A' to `lazyk Main.lazy` must produce 'A'.
# (The TOML compile step is a parse probe that expects exit code 124 because a real
# program keeps reading stdin; with /dev/null stdin during docker build, 'I' sees EOF
# and exits 0 immediately, so we skip reproducing that probe here. A successful execute
# requires the source to parse anyway, so this covers the same ground.)
RUN printf 'I\n' > Main.lazy \
    && OUT=$(printf 'A' | lazyk Main.lazy) \
    && [ "$OUT" = "A" ] \
    && rm Main.lazy
