FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG CHEZ_VERSION=10.2.0

WORKDIR /judge

# Build and install ChezScheme from source
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates wget \
    && mkdir /tmp/chez-install \
    && cd /tmp/chez-install \
    && wget -q "https://github.com/cisco/ChezScheme/releases/download/v${CHEZ_VERSION}/csv${CHEZ_VERSION}.tar.gz" \
    && tar xf "csv${CHEZ_VERSION}.tar.gz" \
    && cd "csv${CHEZ_VERSION}" \
    && ./configure --disable-curses --disable-x11 --installprefix=/usr/local \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/chez-install \
    && rm -rf /var/lib/apt/lists/*

# Install SRFI library
RUN apt-get update \
    && apt-get install -y --no-install-recommends scheme-chez-srfi \
    && rm -rf /var/lib/apt/lists/*

ENV CHEZSCHEMELIBDIRS=.:/usr/share/r6rs
