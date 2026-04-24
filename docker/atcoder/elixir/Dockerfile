FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG OTP_VERSION=28.0.2
ARG ELIXIR_OTP_MAJOR=27

ENV HOME=/root

WORKDIR /judge

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ansifilter build-essential ca-certificates git \
        libatlas-base-dev libssl-dev unixodbc-dev unzip wget \
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

# Install Elixir (OTP 27 binary compatible with OTP 28)
RUN wget -q "https://github.com/elixir-lang/elixir/releases/download/v1.18.4/elixir-otp-${ELIXIR_OTP_MAJOR}.zip" \
        -O /tmp/elixir.zip \
    && unzip -q /tmp/elixir.zip 'bin/*' 'lib/*' -d /usr/local \
    && rm /tmp/elixir.zip

# Set up Mix environment
RUN mix local.hex --force \
    && mix local.rebar --force

# Create Mix project
RUN mix new main \
    && mkdir -p main/config

# Copy project files
COPY mix.exs main/mix.exs
COPY config.exs main/config/config.exs

# Install deps and pre-build release
RUN cd main \
    && printf 'defmodule Main do\n  def main do\n    IO.puts("Hello")\n  end\nend\n' > lib/main.ex \
    && MIX_ENV=prod mix deps.get \
    && MIX_ENV=prod mix release \
    && rm _build/prod/rel/main/bin/main
