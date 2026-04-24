FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

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
