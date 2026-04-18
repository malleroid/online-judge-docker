FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
