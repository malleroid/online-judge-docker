FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG OCAML_VERSION=5.3.0
ARG REASON_VERSION=3.16.0

ENV HOME=/root

WORKDIR /judge

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        opam \
        build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Initialize opam
# --disable-sandboxing: required for running opam inside Docker
RUN opam init -y --disable-sandboxing

RUN opam update \
    && opam upgrade -y

# Create local switch with OCaml compiler
RUN opam switch create . ${OCAML_VERSION} --deps-only

# Install reason and dune
RUN eval $(opam env --switch=.) \
    && opam install -y reason.${REASON_VERSION}

RUN eval $(opam env --switch=.) \
    && opam install -y dune

# Initialize dune project and configure
RUN eval $(opam env --switch=.) \
    && dune init project main

RUN rm main/bin/main.ml

RUN cat > dune << 'EOF'
(env
 (release
  (ocamlopt_flags (:standard -O2))))
EOF
