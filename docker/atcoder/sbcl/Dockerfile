FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

# sb-simd contrib requires x86 SSE/AVX; no arm64 support
# Build with: docker build --platform linux/amd64

ARG SBCL_VERSION=2.5.8

WORKDIR /judge

# Install bootstrap sbcl and build dependencies
RUN apt-get update \
    && apt-get install -y build-essential bzip2 ca-certificates curl wget sbcl \
    && rm -rf /var/lib/apt/lists/*

# Build and install SBCL from source
RUN cd /tmp \
    && wget -q --trust-server-names "https://sourceforge.net/projects/sbcl/files/sbcl/${SBCL_VERSION}/sbcl-${SBCL_VERSION}-source.tar.bz2/download" \
        -O "sbcl-${SBCL_VERSION}-source.tar.bz2" \
    && tar xf "sbcl-${SBCL_VERSION}-source.tar.bz2" \
    && cd "sbcl-${SBCL_VERSION}" \
    && GNUMAKE=make sh make.sh \
    && sh install.sh

# Remove bootstrap sbcl installed via apt
RUN apt-get --purge -y remove sbcl

# Install library dependencies
RUN apt-get update \
    && apt-get install -y libgsl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Quicklisp
RUN cd /tmp \
    && curl -O https://beta.quicklisp.org/quicklisp.lisp \
    && echo '(quicklisp-quickstart:install)' | sbcl --load quicklisp.lisp

# Build custom SBCL image with modules and Quicklisp
COPY dump.lisp /tmp/dump.lisp
RUN cd /tmp \
    && sbcl --noinform --control-stack-size 512 --script dump.lisp \
    && cp -p /tmp/sbcl /judge/sbcl

ENV SBCL_HOME=/usr/local/lib/sbcl

# Install Quicklisp libraries
RUN ./sbcl --eval '(ql:quickload "fast-generic-functions")' --quit \
    && ./sbcl --eval '(ql:quickload "cl-ppcre")' --quit \
    && ./sbcl --eval '(ql:quickload "gsll")' --quit \
    && ./sbcl --eval '(ql:quickload "iterate")' --quit \
    && ./sbcl --eval '(ql:quickload "pileup")' --quit \
    && ./sbcl --eval '(ql:quickload "queues")' --quit \
    && ./sbcl --eval '(ql:quickload "str")' --quit \
    && ./sbcl --eval '(ql:quickload "trees")' --quit \
    && ./sbcl --eval '(ql:quickload "trivia")' --quit
