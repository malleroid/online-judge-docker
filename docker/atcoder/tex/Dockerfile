FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

WORKDIR /judge

# Install TeX
# Note: TOML specifies texlive-binaries, but it lacks tex.fmt (format file).
# texlive-plain-generic includes texlive-binaries + format files needed to run tex.
RUN apt-get update \
    && apt-get install -y --no-install-recommends texlive-plain-generic \
    && rm -rf /var/lib/apt/lists/*

ENV max_print_line=2147483647

# Copy execution wrapper script
COPY tex.sh tex.sh
