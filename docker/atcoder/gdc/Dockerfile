FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG GDC_VERSION=15
ARG MIR_VERSION=3.2.3

# dub binary from GitHub is x86_64 only
# Build with: docker build --platform linux/amd64

ENV HOME=/root

WORKDIR /judge

# Add PPA and install GDC
RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:puni070/gcc-noble \
    && apt-get install -y \
        ca-certificates curl gdc-${GDC_VERSION} \
        libgmp-dev libisl-dev libmpc-dev libmpfr-dev libzstd-dev wget zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install dub from GitHub releases
RUN DUB_URL=$(curl -s https://api.github.com/repos/dlang/dub/releases/latest | grep browser_download_url | grep linux-x86_64.tar.gz | awk '{ print $NF }' | sed 's/"//g') \
    && wget -q -O /tmp/dub.tar.gz "$DUB_URL" \
    && tar -C /usr/local/bin -xf /tmp/dub.tar.gz \
    && rm /tmp/dub.tar.gz

# Initialize dub project and fetch dependencies
RUN dub init -n \
    && dub add mir@${MIR_VERSION} \
    && for pkg in mir mir-random mir-core mir-linux-kernel mir-algorithm; do \
        dub fetch "$pkg" 2>&1; \
    done

# Apply GDC compatibility patches for mir
RUN sed -i 's/auto return ref/auto ref return/' ${HOME}/.dub/packages/mir-core/*/mir-core/source/mir/exception.d \
    && sed -i 's/auto return ref/auto ref return/' ${HOME}/.dub/packages/mir-core/*/mir-core/source/mir/qualifier.d \
    && sed -i 's/auto scope ref/auto ref scope/' ${HOME}/.dub/packages/mir-algorithm/*/mir-algorithm/source/mir/format.d \
    && sed -i 's/auto scope ref/auto ref scope/' ${HOME}/.dub/packages/mir-algorithm/*/mir-algorithm/source/mir/interpolate/spline.d

# Pre-build with manual gdc to verify compilation works
RUN SOURCES=""; \
    for dir in ${HOME}/.dub/packages/*/; do \
        for subdir in "$dir"/*/; do \
            for pkgdir in "$subdir"/*/; do \
                if [ -d "${pkgdir}source" ]; then \
                    SOURCES="$SOURCES -I${pkgdir}source"; \
                fi; \
            done; \
        done; \
    done; \
    echo "void main(){}" > source/app.d \
    && gdc-${GDC_VERSION} source/app.d -o judge $SOURCES \
    && rm judge source/app.d
