FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

# Emojicode 1.0-beta.2 only provides an x86_64 Linux prebuilt binary; arm64 is not supported upstream.
# Build with: docker build --platform linux/amd64

ARG EMOJICODE_VERSION=1.0-beta.2
ARG EMOJICODE_SHA256=c2e4a8ec156c198a80d844e747ce71c9d34efd54a2c5f3b6a116470d0cb8ef0f
ARG LIBTINFO5_VERSION=6.3-2ubuntu0.1
ARG LIBTINFO5_SHA256=ab89265d8dd18bda6a29d7c796367d6d9f22a39a8fa83589577321e7caf3857b

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        g++ \
        rsync \
        wget \
    && rm -rf /var/lib/apt/lists/*

# libtinfo5 is no longer provided by Ubuntu 24.04; pull the Jammy-era .deb from security.ubuntu.com
# and verify it against a pinned sha256 before installing with apt (to resolve transitive deps).
RUN cd /tmp \
    && wget -q -O libtinfo5.deb "http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_${LIBTINFO5_VERSION}_amd64.deb" \
    && echo "${LIBTINFO5_SHA256}  libtinfo5.deb" | sha256sum -c - \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./libtinfo5.deb \
    && rm -rf /var/lib/apt/lists/* \
    && rm libtinfo5.deb

RUN cd /tmp \
    && wget -q -O emojicode.tar.gz "https://github.com/emojicode/emojicode/releases/download/v${EMOJICODE_VERSION}/Emojicode-${EMOJICODE_VERSION}-Linux-x86_64.tar.gz" \
    && echo "${EMOJICODE_SHA256}  emojicode.tar.gz" | sha256sum -c - \
    && tar -xzf emojicode.tar.gz \
    && cd "Emojicode-${EMOJICODE_VERSION}-Linux-x86_64" \
    && yes | ./install.sh \
    && cd /tmp \
    && rm -rf "Emojicode-${EMOJICODE_VERSION}-Linux-x86_64" emojicode.tar.gz

# Smoke test: compile and run a minimal program through the TOML's exact command
# to catch toolchain breakage (emojicodec + g++ + linker) at image build time.
COPY SmokeMain.🍇 /tmp/SmokeMain.🍇
RUN cd /tmp \
    && emojicodec SmokeMain.🍇 -O -o a.out 1>&2 \
    && test "$(./a.out)" = "smoke-ok" \
    && rm -f SmokeMain.🍇 a.out
