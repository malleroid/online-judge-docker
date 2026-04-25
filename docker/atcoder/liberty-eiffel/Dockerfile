FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG LIBERTY_EIFFEL_COMMIT=07829e3
ARG LIBERTY_EIFFEL_TARBALL_SHA256=331632ce114553605e55c3016d710b0d402355ef5ce2f97f5eaec373b1cbae34

WORKDIR /judge

# `libgc-dev` and `libcurl4-openssl-dev` come straight from the TOML.
# `gcc` / `g++` / `libc6-dev` / `make` are the bootstrap toolchain the
# AtCoder judge image already provides; on bare ubuntu:24.04 we have to
# add them explicitly. They stay in the final image because
# `se c main --boost` invokes gcc at judge time and links against the
# Boehm GC and libcurl runtimes. `bsdextrautils` provides `script(1)`,
# which we use to wrap install.sh in a pseudo-tty — Liberty's install.sh
# opens /dev/tty directly for status updates, and Docker build has no
# tty, so without `script` the install loops forever printing
# "/dev/tty: No such device or address".
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bsdextrautils \
        ca-certificates \
        g++ \
        gcc \
        libc6-dev \
        libcurl4-openssl-dev \
        libgc-dev \
        make \
        wget \
    && rm -rf /var/lib/apt/lists/*

# TOML install step, preserved line-for-line:
#   1.  cd /tmp
#   2.  wget https://github.com/LibertyEiffel/Liberty/archive/07829e3.tar.gz
#   3.  mkdir liberty-eiffel
#   4.  tar -C liberty-eiffel --strip-components=1 -xf liberty-eiffel.tar.gz
#   5.  export TERM=vt100      (silences install.sh's tty probes on a dumb
#                                terminal)
#   6.  cd liberty-eiffel
#   7.  sed -i 's@/usr/lib@$USRDIR/lib@;s@/usr/share@$USRDIR/share@;
#                 s/do_.*_doc$//;
#                 s/LOCAL_MAN_PATH]/LOCAL_MAN_PATH ]/;
#                 s/.*LOCAL_MAN_PATH$//' install.sh
#   8.  ./install.sh                       (first pass: bootstrap into
#                                            ./target/)
#   9.  yes '' | ./install.sh -local_install (second pass: deploy to
#                                              /usr/local; `yes ''`
#                                              answers the prompt)
#   10. ln -s /usr/local/etc/xdg/liberty-eiffel /etc/xdg/
# The sed batch is critical: the `$USRDIR` substitutions retarget paths
# to /usr/local for the system install, `do_*_doc` strips out the
# eiffeldoc passes (slow and prone to failure), the LOCAL_MAN_PATH
# bracket fix repairs an `[ ! -d $X]` syntax error in upstream
# install.sh, and the trailing LOCAL_MAN_PATH wipe stops install.sh
# from copying manpages into the build user's home. `sudo` from the
# TOML is dropped because Docker runs as root.
COPY smoke/main.e /tmp/smoke/main.e
RUN set -eu; \
    cd /tmp \
    && wget -nv -O liberty-eiffel.tar.gz \
        "https://github.com/LibertyEiffel/Liberty/archive/${LIBERTY_EIFFEL_COMMIT}.tar.gz" \
    && echo "${LIBERTY_EIFFEL_TARBALL_SHA256}  liberty-eiffel.tar.gz" | sha256sum -c - \
    && mkdir liberty-eiffel \
    && tar -C liberty-eiffel --strip-components=1 -xf liberty-eiffel.tar.gz \
    && export TERM=vt100 \
    && cd liberty-eiffel \
    && sed -i 's@/usr/lib@$USRDIR/lib@;s@/usr/share@$USRDIR/share@;s/do_.*_doc$//;s/LOCAL_MAN_PATH]/LOCAL_MAN_PATH ]/;s/.*LOCAL_MAN_PATH$//' install.sh \
    && script -qec './install.sh' /dev/null \
    && script -qec 'yes "" | ./install.sh -local_install' /dev/null

# `/etc/xdg/` does not exist in ubuntu:24.04 by default, so `mkdir -p`
# before the symlink. The TOML's `sudo ln -s /usr/local/etc/xdg/...
# /etc/xdg/` assumes the directory is already present (the AtCoder
# judge base image has it).
RUN mkdir -p /etc/xdg \
    && ln -s /usr/local/etc/xdg/liberty-eiffel /etc/xdg/

# Remove the user-level XDG config that install.sh's first pass leaves
# behind under $HOME/.config/liberty-eiffel/. Both that file and the
# system-level configs in /etc/xdg/liberty-eiffel/ get loaded when `se`
# runs (XDG_CONFIG_HOME wins, then XDG_CONFIG_DIRS), which makes Liberty
# see `core:` and `liberty_core:` as duplicate clusters and abort with
# "More than one class in the system is named ANY". The TOML's two-pass
# install on AtCoder's judge image works because the judge separates
# install user from runtime user; in Docker we install and run as root,
# so we have to drop the per-user config explicitly. Source/lib trees
# under /root/.local/ are also cleared in case the user-pass copied
# anything there.
RUN rm -rf /root/.config/liberty-eiffel \
    /root/.local/share/liberty-eiffel \
    /root/.local/lib/liberty-eiffel

# Smoke test: reproduce the TOML compile/execute flow end-to-end. Uses
# the canonical Liberty Eiffel hello class compiled with `--boost`
# (assertions stripped, gcc -O3-equivalent flags) — same flags the TOML
# compile step uses.
RUN set -eu; \
    cd /tmp/smoke \
    && se c main --boost -o a.out \
    && out="$(./a.out)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && cd / \
    && rm -rf /tmp/smoke /tmp/liberty-eiffel /tmp/liberty-eiffel.tar.gz

RUN apt-get purge -y --auto-remove wget \
    && rm -rf /var/lib/apt/lists/*
