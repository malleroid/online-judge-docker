FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG OCAML_VERSION=5.3.0
ARG NUM_VERSION=1.6
ARG ZARITH_VERSION=1.14
ARG CONTAINERS_VERSION=3.16
ARG CORE_VERSION=v0.17.1
ARG ITER_VERSION=1.9
ARG BATTERIES_VERSION=3.9.0

ENV HOME=/root

WORKDIR /judge

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        opam libgmp-dev pkg-config \
        build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Initialize opam and create switch with flambda
RUN opam init -y --disable-sandboxing \
    && opam switch create ${OCAML_VERSION}+flambda \
        ocaml-variants.${OCAML_VERSION}+options ocaml-option-flambda.1

# Install OCaml libraries
RUN eval $(opam env --switch=${OCAML_VERSION}+flambda) \
    && opam install -y \
        num=${NUM_VERSION} \
        zarith=${ZARITH_VERSION} \
        containers=${CONTAINERS_VERSION} \
        core=${CORE_VERSION} \
        iter=${ITER_VERSION} \
        batteries=${BATTERIES_VERSION}

# Set opam environment for all subsequent commands
ENV PATH="/root/.opam/${OCAML_VERSION}+flambda/bin:${PATH}" \
    OCAML_TOPLEVEL_PATH="/root/.opam/${OCAML_VERSION}+flambda/lib/toplevel" \
    CAML_LD_LIBRARY_PATH="/root/.opam/${OCAML_VERSION}+flambda/lib/stublibs:/root/.opam/${OCAML_VERSION}+flambda/lib/ocaml/stublibs:/root/.opam/${OCAML_VERSION}+flambda/lib/ocaml"
