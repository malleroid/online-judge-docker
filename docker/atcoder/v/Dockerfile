FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG V_VERSION=0.4.10

# V only provides x86_64 binaries; no arm64 support
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# Install dependencies (clang is V's C backend)
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates clang git unzip wget \
    && rm -rf /var/lib/apt/lists/*

# Install V from pre-compiled binary
RUN wget -q "https://github.com/vlang/v/releases/download/${V_VERSION}/v_linux.zip" -O /tmp/v_linux.zip \
    && unzip -q /tmp/v_linux.zip \
    && cd v \
    && ./v symlink \
    && cd /judge \
    && rm /tmp/v_linux.zip

# Install libraries
RUN v install vsl \
    && v install vtl \
    && v install lemoncmd.proconio
