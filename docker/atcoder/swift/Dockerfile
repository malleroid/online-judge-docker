FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG SWIFT_VERSION=6.2
ARG SWIFT_RELEASE=6.2-RELEASE
ARG SWIFT_PLATFORM=ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SWIFT_BACKTRACE="enable=yes,output-to=stderr,interactive=no"
ENV SWIFTPM_MAX_CONCURRENT_OPERATIONS=1
ENV SWIFT_AC_LIBRARY_USES_O_UNCHECKED=true

WORKDIR /judge

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils ca-certificates curl git gnupg2 \
        libc6-dev libcurl4-openssl-dev libedit2 \
        libgcc-13-dev libncurses-dev libpython3-dev \
        libsqlite3-0 libstdc++-13-dev libxml2-dev \
        libz3-dev pkg-config tzdata unzip zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install OpenBLAS and LAPACK (for accelerate-linux)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libopenblas-dev libopenblas-pthread-dev \
        liblapacke-dev libtmglib-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and install Swift toolchain
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN SWIFT_ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "-aarch64" || echo "") \
    && SWIFT_PLATFORM_URL_BASE=$(echo ${SWIFT_PLATFORM} | tr -d .) \
    && SWIFT_PLATFORM_URL=$([ "$TARGETARCH" = "arm64" ] && echo "${SWIFT_PLATFORM_URL_BASE}-aarch64" || echo "${SWIFT_PLATFORM_URL_BASE}") \
    && curl -sL "https://download.swift.org/swift-${SWIFT_VERSION}-release/${SWIFT_PLATFORM_URL}/swift-${SWIFT_RELEASE}/swift-${SWIFT_RELEASE}-${SWIFT_PLATFORM}${SWIFT_ARCH_SUFFIX}.tar.gz" \
        -o /tmp/swift.tar.gz \
    && tar -C /judge -xzf /tmp/swift.tar.gz \
    && rm /tmp/swift.tar.gz

ENV PATH="/judge/swift-${SWIFT_RELEASE}-${SWIFT_PLATFORM}/usr/bin:/judge/swift-${SWIFT_RELEASE}-${SWIFT_PLATFORM}-aarch64/usr/bin:${PATH}"

# Set up Swift package project
RUN mkdir -p Package/Sources \
    && echo 'print("Hello, world!")' > Package/Sources/main.swift

COPY Package.swift Package/Package.swift

# Resolve dependencies and build
RUN cd Package \
    && swift package clean \
    && swift package resolve \
    && cd /judge \
    && swift build \
        --product Main \
        --build-system native \
        --jobs 1 \
        --configuration release \
        --package-path Package \
        2>&1 | tee /dev/null \
    && rm -f Package/.build/release/Main

# Verify build artifacts exist (for incremental compilation)
RUN ls Package/.build/
