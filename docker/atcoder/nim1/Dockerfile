FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG NIM_VERSION=1.6.20
ARG BOOST_VERSION=1.88.0
ARG EIGEN_VERSION=3.4.0
ARG ACL_VERSION=1.5.1

# choosenim and Nim binaries are x86_64 only; no arm64 support
# Build with: docker build --platform linux/amd64

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /judge

# Set timezone
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime \
    && echo Etc/UTC > /etc/timezone

# Install base packages
RUN apt-get update \
    && apt-get install -y bzip2 curl g++ git lsb-release software-properties-common wget gnupg xz-utils

# Install LLVM 20
RUN wget -q https://apt.llvm.org/llvm.sh -O /tmp/llvm.sh \
    && chmod +x /tmp/llvm.sh \
    && /tmp/llvm.sh 20 all \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-20 1 \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-20 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && rm /tmp/llvm.sh

# Install Nim via choosenim
RUN export CHOOSENIM_CHOOSE_VERSION=${NIM_VERSION} \
    && curl https://nim-lang.org/choosenim/init.sh -sSf | bash -s -- -y

ENV PATH="${HOME}/.nimble/bin:${PATH}"

# Install system libraries for nimble packages
RUN apt-get install -y libfftw3-dev libgmp3-dev liblapack-dev libmpfr-dev libopenblas-dev python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Nimble packages
RUN nimble install neo@0.3.5 -y \
    && nimble install https://github.com/zer0-star/Nim-ACL@0.1.0 -y \
    && nimble install https://github.com/chaemon/bignum@1.0.6 -y \
    && nimble install "https://github.com/nim-lang/bigints@#ca00f6da386af9ad7e3abf603c0201da6a014477" -y \
    && nimble install "arraymancer@#84af537af1bc1f90229fff2b90abf5e5c1b02616" -y \
    && nimble install regex@0.26.3 -y \
    && nimble install nimsimd@1.3.2 -y \
    && nimble install "https://github.com/nim-lang/sat@#faf1617f44d7632ee9601ebc13887644925dcc01" -y

# Build and install Boost
RUN wget -q "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_$(echo ${BOOST_VERSION} | tr . _).tar.gz" \
        -O /tmp/boost.tar.gz \
    && tar -C /tmp -xf /tmp/boost.tar.gz \
    && cd /tmp/boost_$(echo ${BOOST_VERSION} | tr . _) \
    && ./bootstrap.sh --without-libraries=mpi,graph_parallel \
    && ./b2 install \
    && ldconfig \
    && rm -rf /tmp/boost*

# Install Eigen headers
RUN wget -q "https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_VERSION}/eigen-${EIGEN_VERSION}.tar.gz" \
        -O /tmp/eigen.tar.gz \
    && tar -C /tmp -xf /tmp/eigen.tar.gz \
    && cp -r /tmp/eigen-${EIGEN_VERSION}/Eigen/ /tmp/eigen-${EIGEN_VERSION}/unsupported/ /usr/local/include/ \
    && rm -rf /tmp/eigen*

# Install AC Library headers
RUN wget -q "https://github.com/atcoder/ac-library/archive/refs/tags/v${ACL_VERSION}.tar.gz" \
        -O /tmp/acl.tar.gz \
    && tar -C /tmp -xf /tmp/acl.tar.gz \
    && cp -r /tmp/ac-library-${ACL_VERSION}/atcoder /usr/local/include \
    && rm -rf /tmp/acl* /tmp/ac-library*
