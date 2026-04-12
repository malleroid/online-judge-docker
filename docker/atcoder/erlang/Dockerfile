FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG OTP_VERSION=28.0.2

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
