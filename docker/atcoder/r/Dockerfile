FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

# R deb packages from CRAN are amd64 only; no arm64 support
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# Install R 4.5.0 from CRAN deb packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && mkdir /tmp/r-install \
    && cd /tmp/r-install \
    && wget -q https://cloud.r-project.org/bin/linux/ubuntu/noble-cran40/r-base-core_4.5.0-3.2404.0_amd64.deb \
    && wget -q https://cloud.r-project.org/bin/linux/ubuntu/noble-cran40/r-recommended_4.5.0-3.2404.0_all.deb \
    && wget -q https://cloud.r-project.org/bin/linux/ubuntu/noble-cran40/r-base_4.5.0-3.2404.0_all.deb \
    && wget -q https://cloud.r-project.org/bin/linux/ubuntu/noble-cran40/r-base-dev_4.5.0-3.2404.0_all.deb \
    && apt-get install -y ./r-base-core_4.5.0-3.2404.0_amd64.deb \
    && apt-get install -y ./r-recommended_4.5.0-3.2404.0_all.deb \
    && apt-get install -y ./r-base_4.5.0-3.2404.0_all.deb \
    && apt-get install -y ./r-base-dev_4.5.0-3.2404.0_all.deb \
    && rm -rf /tmp/r-install /var/lib/apt/lists/*

# Install R packages with pinned versions
COPY install-packages.R /tmp/install-packages.R
RUN Rscript /tmp/install-packages.R \
    && rm /tmp/install-packages.R
