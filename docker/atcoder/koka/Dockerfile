FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

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
