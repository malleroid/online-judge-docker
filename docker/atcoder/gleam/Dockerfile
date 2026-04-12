FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG TARGETARCH
ARG OTP_VERSION=28.0.2
ARG GLEAM_VERSION=1.12.0

WORKDIR /judge

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates libssl-dev unixodbc-dev wget \
    && rm -rf /var/lib/apt/lists/*

# Build and install Erlang OTP from source
RUN wget -q "https://github.com/erlang/otp/releases/download/OTP-${OTP_VERSION}/otp_src_${OTP_VERSION}.tar.gz" \
        -O /tmp/erlang.tar.gz \
    && mkdir /tmp/erlang \
    && tar -C /tmp/erlang --strip-components=1 -xf /tmp/erlang.tar.gz \
    && cd /tmp/erlang \
    && ./configure --without-termcap \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/erlang*

# Install Gleam binary
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN GLEAM_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") \
    && wget -q "https://github.com/gleam-lang/gleam/releases/download/v${GLEAM_VERSION}/gleam-v${GLEAM_VERSION}-${GLEAM_ARCH}-unknown-linux-musl.tar.gz" \
        -O /tmp/gleam.tar.gz \
    && tar -C /usr/local/bin -xf /tmp/gleam.tar.gz \
    && rm /tmp/gleam.tar.gz

# Create Gleam project and install libraries
RUN gleam new . \
    && gleam add \
        bidict@1.0.0 \
        bigdecimal@1.1.0 \
        bitsandbobs@1.1.0 \
        dijkstra@1.0.0 \
        gleam_community_maths@2.0.0 \
        gleam_deque@1.0.0 \
        gleam_regexp@1.1.1 \
        gleam_stdlib@0.63.0 \
        gleam_yielder@1.1.0 \
        gleamy_structures@1.2.0 \
        glearray@2.1.0 \
        ieee_float@1.5.0 \
        iv@1.3.2 \
        stdin@2.0.2 \
        trie_again@1.1.3 \
    && gleam remove gleeunit \
    && rm -rf test

# Pre-build dependencies
RUN gleam build \
    && gleam run --no-print-progress \
    && rm -rf build/dev/erlang/judge
