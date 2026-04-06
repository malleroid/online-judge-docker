FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

WORKDIR /judge

# Install Fish from PPA
RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:fish-shell/release-4 \
    && apt-get update \
    && apt-get install -y --no-install-recommends fish \
    && rm -rf /var/lib/apt/lists/*
