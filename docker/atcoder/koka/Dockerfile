FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

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
