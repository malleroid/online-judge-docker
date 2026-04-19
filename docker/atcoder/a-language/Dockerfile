FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG A_COMMIT=af48a2a058d625f9a12f4695a31d0d3fede6d517
ARG A_SHA256=b9e2a746226fce07d6ac6e181c90e2935a75e206629439b089d2e2e69a080ac1

WORKDIR /judge

# Install build dependencies.
# - build-essential: g++ + make to build the A language interpreter from source
# - ca-certificates: HTTPS for archive fetch
# - curl: project-standard for downloading release archives
# - unzip: required to extract the GitHub archive zip (TOML uses `unzip`)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Fetch, verify, build, and install the A language interpreter (snuke/a @ af48a2a).
# Pure C++ standard library, no arch-specific code, so it builds cleanly on amd64/arm64.
# The TOML installs both `interpreter` and `compiler` via the default `make` target, but
# only uses `interpreter` at execution time; we build only `interpreter` to keep the image
# minimal.
RUN curl -fsSL -o /tmp/a.zip \
        "https://github.com/snuke/a/archive/${A_COMMIT}.zip" \
    && echo "${A_SHA256}  /tmp/a.zip" | sha256sum -c - \
    && unzip -q /tmp/a.zip -d /tmp \
    && make -C /tmp/a-${A_COMMIT} interpreter \
    && cp /tmp/a-${A_COMMIT}/interpreter /usr/local/bin/interpreter \
    && rm -rf /tmp/a.zip /tmp/a-${A_COMMIT}

# Smoke test: reproduce the TOML execute flow end-to-end. `OMc65` parses char-mode
# literal 65 ('A') and prints it; verify the output matches.
RUN printf '%s' 'OMc65' > Main.a \
    && OUT=$(interpreter Main.a) \
    && [ "$OUT" = "A" ] \
    && rm Main.a
