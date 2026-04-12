FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG CLOJURE_INSTALLER_VERSION=1.12.2.1565

WORKDIR /judge

# Install JDK and dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl openjdk-21-jre-headless rlwrap wget \
    && rm -rf /var/lib/apt/lists/*

# Install Clojure CLI
RUN curl -sL "https://github.com/clojure/brew-install/releases/download/${CLOJURE_INSTALLER_VERSION}/linux-install.sh" \
        -o /tmp/linux-install.sh \
    && chmod +x /tmp/linux-install.sh \
    && /tmp/linux-install.sh \
    && rm /tmp/linux-install.sh

# Download ac-library-java JAR
RUN mkdir -p lib \
    && wget -q -O lib/ac_library.jar https://github.com/ocha98/ac-library-java/releases/download/v2.0.0/ac_library21.jar

# Copy project files
COPY deps.edn deps.edn
COPY clojure.sh clojure.sh

# Pre-build: resolve Maven dependencies and warm up
RUN printf '(println "Hello")\n' > Main.clj \
    && sh clojure.sh 2048 \
    && rm Main.clj
