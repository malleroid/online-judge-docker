FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG KOTLIN_VERSION=2.2.10

WORKDIR /judge

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip wget \
    && rm -rf /var/lib/apt/lists/*

# Install Kotlin Compiler
RUN wget -q "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
        -O /tmp/kotlin-compiler.zip \
    && unzip -q /tmp/kotlin-compiler.zip -d /usr/local \
    && rm /tmp/kotlin-compiler.zip

# Install OpenJDK 23.0.2
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN JDK_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x64") \
    && curl -sL "https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_linux-${JDK_ARCH}_bin.tar.gz" \
        | tar zx -C /usr/local --strip-components=1

# Download library JARs
RUN wget -q -O ac_library.jar https://github.com/ocha98/ac-library-java/releases/download/v2.0.0/ac_library23.jar \
    && wget -q -O kotlinx-collections-immutable-jvm.jar https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-collections-immutable-jvm/0.4.0/kotlinx-collections-immutable-jvm-0.4.0.jar

# Copy execution wrapper script
COPY kotlin.sh kotlin.sh
