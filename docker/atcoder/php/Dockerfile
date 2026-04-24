FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /judge

# Install PHP 8.4 from ondrej/php PPA
RUN apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y php8.4-cli php8.4-bcmath php8.4-gmp php8.4-sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Enable OPcache + JIT (tracing mode)
RUN printf 'opcache.enable_cli = 1\nopcache.jit = tracing\nopcache.jit_buffer_size = 128M\n' \
    >> /etc/php/8.4/cli/conf.d/10-opcache.ini
