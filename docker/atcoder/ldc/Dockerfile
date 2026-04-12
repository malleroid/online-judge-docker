FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG LDC_VERSION=ldc-1.41.0

ENV HOME=/root

WORKDIR /judge

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates curl libxml2 wget \
    && rm -rf /var/lib/apt/lists/*

# Install LDC via dlang.org install script
RUN wget -q https://dlang.org/install.sh -O /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh install ${LDC_VERSION} \
    && ln -s $(/tmp/install.sh get-path ${LDC_VERSION}) /usr/local/bin/ldc2 \
    && ln -s $(/tmp/install.sh get-path --dmd ${LDC_VERSION}) /usr/local/bin/ldmd2 \
    && ln -s $(/tmp/install.sh get-path --dub ${LDC_VERSION}) /usr/local/bin/dub

# Initialize dub project and fetch dependencies
# Note: dub build may fail under QEMU (D runtime fork+exec issue),
# so we fetch deps and do a manual compile for pre-build verification
RUN dub init -n \
    && dub add mir@3.2.3 \
    && for pkg in mir mir-random mir-core mir-linux-kernel mir-algorithm; do \
        dub fetch "$pkg" 2>&1; \
    done

# Pre-build with manual ldc2 to verify compilation works
RUN SOURCES=""; \
    for dir in /root/.dub/packages/*/; do \
        for subdir in "$dir"/*/; do \
            for pkgdir in "$subdir"/*/; do \
                if [ -d "${pkgdir}source" ]; then \
                    SOURCES="$SOURCES -I${pkgdir}source"; \
                fi; \
            done; \
        done; \
    done; \
    echo "void main(){}" > source/app.d \
    && ldmd2 source/app.d -of=judge $SOURCES \
    && rm judge source/app.d
