FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG TARGETARCH
ARG DART_VERSION=3.9.2

WORKDIR /judge

# Install system dependencies (libz3 for z3 pub package FFI)
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libz3-dev wget unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Dart SDK
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN DART_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") \
    && wget -q "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-${DART_ARCH}-release.zip" \
        -O /tmp/dart-sdk.zip \
    && unzip -q /tmp/dart-sdk.zip -d /opt \
    && rm /tmp/dart-sdk.zip

ENV PATH="/opt/dart-sdk/bin:${PATH}"

RUN dart --disable-analytics

# Create project and install packages
RUN dart create judge \
    && cd judge \
    && dart pub add \
        advance_math \
        bit_array \
        collection \
        decimal \
        fast_immutable_collections \
        min_max_heap \
        more \
        ordered_set \
        scidart \
        segment_tree \
        sorted_list \
        sortedmap \
        z3 \
    && dart pub remove test lints

# Place dummy entry point (user replaces this)
RUN echo 'void main() {}' > judge/bin/judge.dart
