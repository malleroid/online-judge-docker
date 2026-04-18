FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
