FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG OCTAVE_VERSION=10.2.0

WORKDIR /judge

# Install build dependencies
# https://wiki.octave.org/Octave_for_Debian_systems
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf automake bison ca-certificates dvipng epstool fig2dev flex \
        g++ gcc gfortran gnuplot-x11 gperf gzip icoutils \
        libarpack2-dev libcurl4-gnutls-dev libfftw3-dev libfltk1.3-dev \
        libfontconfig1-dev libfreetype-dev libgl1-mesa-dev libgl2ps-dev \
        libglpk-dev libgraphicsmagick++1-dev libhdf5-dev liblapack-dev \
        libopenblas-dev libosmesa6-dev libpcre2-dev libqhull-dev \
        libqscintilla2-qt5-dev libqrupdate-dev libreadline-dev librsvg2-bin \
        libsndfile1-dev libsuitesparse-dev libsundials-dev libtool libxft-dev \
        make openjdk-11-jdk perl portaudio19-dev pstoedit \
        qtbase5-dev qttools5-dev qttools5-dev-tools rapidjson-dev rsync \
        tar texinfo texlive-latex-extra wget zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Build and install GNU Octave from source
RUN wget -q --content-disposition "https://ftpmirror.gnu.org/octave/octave-${OCTAVE_VERSION}.tar.xz" -O /tmp/octave.tar.xz \
    && tar -C /tmp -xf /tmp/octave.tar.xz \
    && mkdir /tmp/octave-${OCTAVE_VERSION}/.build \
    && cd /tmp/octave-${OCTAVE_VERSION}/.build \
    && ../configure \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/octave*
