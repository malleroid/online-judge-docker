FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG TARGETARCH
ARG ZIG_VERSION=0.15.1

WORKDIR /judge

# Install dependencies (git needed for library clone + patch)
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git patch wget xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Zig from official binary
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN ZIG_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") \
    && wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" \
        -O /tmp/zig.tar.xz \
    && tar -C /opt -xf /tmp/zig.tar.xz \
    && ln -s /opt/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}/zig /usr/local/bin/zig \
    && rm /tmp/zig.tar.xz

# Initialize project
RUN zig init \
    && rm src/root.zig

# Install libraries (ac-library-zig, proconio-zig)
RUN zig fetch --save=ac-library git+https://github.com/Ryoga-exe/ac-library-zig#v0.4.0 \
    && zig fetch --save=proconio git+https://github.com/Ryoga-exe/proconio-zig#v0.3.0

# Install patched libraries (zig-string, mvzr)
RUN git clone https://github.com/JakubSzark/zig-string /tmp/zig-string \
    && wget -nv -O /tmp/string.patch https://github.com/JakubSzark/zig-string/pull/55.patch \
    && cd /tmp/zig-string \
    && git checkout f6f9e5dc7c5c45a72473de245a0e6958ef2bf913 \
    && patch -p1 < /tmp/string.patch \
    && git clone https://github.com/mnemnion/mvzr /tmp/mvzr \
    && wget -nv -O /tmp/mvzr.patch https://github.com/mnemnion/mvzr/pull/10.patch \
    && cd /tmp/mvzr \
    && git checkout v0.3.6 \
    && patch -p1 < /tmp/mvzr.patch \
    && cd /judge \
    && zig fetch --save=string /tmp/zig-string \
    && zig fetch --save=mvzr /tmp/mvzr \
    && rm -rf /tmp/zig-string /tmp/mvzr /tmp/*.patch

# Set up build.zig
COPY build.zig build.zig

# Test build to populate cache, then clean binary
RUN echo 'pub fn main() !void {}' > src/main.zig \
    && zig build --release -Doptimize=ReleaseFast \
    && rm zig-out/bin/judge
