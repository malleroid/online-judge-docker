FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

WORKDIR /judge

# Install SWI-Prolog from PPA
RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && apt-add-repository -y ppa:swi-prolog/stable \
    && apt-get update \
    && apt-get install -y --no-install-recommends swi-prolog \
    && rm -rf /var/lib/apt/lists/*
