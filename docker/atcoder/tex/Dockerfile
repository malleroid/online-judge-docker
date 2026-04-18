FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
