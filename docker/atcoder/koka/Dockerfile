FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG KOKA_VERSION=v3.2.2

WORKDIR /judge

# Install curl and run apt-get update (Koka installer needs apt lists)
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl

# Install Koka (installer runs apt-get install internally)
RUN curl -sSL "https://github.com/koka-lang/koka/releases/download/${KOKA_VERSION}/install.sh" | sh \
    && rm -rf /var/lib/apt/lists/*

# Pre-compile standard library to speed up compilation
RUN printf 'fun main()\n  "Hello".println\n' > main.kk \
    && koka -O2 --no-debug -o a.out main.kk --buildtag=atcoder --no-buildhash -v0 \
    && cd ".koka/${KOKA_VERSION}-atcoder/gcc-release" \
    && rm -f main* a \
    && cd /judge \
    && rm main.kk a.out
