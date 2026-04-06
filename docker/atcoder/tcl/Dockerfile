FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG TCL_VERSION=9.0.1
ARG TCLLIB_VERSION=2.0

WORKDIR /judge

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates curl zlib1g zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Build and install Tcl from source
RUN curl -fL "http://prdownloads.sourceforge.net/tcl/tcl${TCL_VERSION}-src.tar.gz" -o /tmp/tcl.tar.gz \
    && tar -C /tmp -xzf /tmp/tcl.tar.gz \
    && cd /tmp/tcl${TCL_VERSION}/unix \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && rm -rf /tmp/tcl*

# Install Tcllib (standard library)
RUN curl -fL "https://core.tcl-lang.org/tcllib/uv/tcllib-${TCLLIB_VERSION}.tar.gz" -o /tmp/tcllib.tar.gz \
    && tar -C /tmp -xzf /tmp/tcllib.tar.gz \
    && cd /tmp/tcllib-${TCLLIB_VERSION} \
    && ./configure --prefix=/usr/local \
    && make install-libraries \
    && rm -rf /tmp/tcllib*
