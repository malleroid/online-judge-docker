FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH

WORKDIR /judge

# Install curl and wget
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl wget \
    && rm -rf /var/lib/apt/lists/*

# Install OpenJDK 24.0.2
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN JDK_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x64") \
    && curl -sL "https://download.java.net/java/GA/jdk24.0.2/fdc5d0102fe0414db21410ad5834341f/12/GPL/openjdk-24.0.2_linux-${JDK_ARCH}_bin.tar.gz" \
        | tar zx -C /usr/local --strip-components=1

# Download library JARs
RUN wget -q -O ac_library.jar https://github.com/ocha98/ac-library-java/releases/download/v2.0.0/ac_library23.jar \
    && wget -q -O bifurcan.jar https://repo1.maven.org/maven2/io/lacuna/bifurcan/0.2.0-rc1/bifurcan-0.2.0-rc1.jar

# Copy execution wrapper script
COPY java.sh java.sh
