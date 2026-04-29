FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG EMACS_VERSION=29.4
ARG EMACS_SHA256=1adb1b9a2c6cdb316609b3e86b0ba1ceb523f8de540cfdda2aec95b6a5343abf

# `package-install` writes to `~/.emacs.d/elpa/` and native-compile caches
# `.eln` files under `~/.emacs.d/eln-cache/`; both build-time and runtime
# resolve `~` to the same path so the compiled artefacts are reachable
# at `package-initialize` time.
ENV HOME=/root

WORKDIR /judge

# TOML install (L1-L4): build deps + switch /usr/bin/gcc to gcc-14.
# Native compilation requires gcc and libgccjit major versions to match,
# so the symlink swap is critical and must be preserved verbatim.
# `libtinfo-dev` is a virtual package provided by `libncurses-dev` on noble.
# `ca-certificates` is added beyond the TOML — the AtCoder judge image
# carries it implicitly; ubuntu:24.04 minimal does not, and `wget` over
# https needs it.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        gcc-14 \
        libgccjit-14-dev \
        libgnutls28-dev \
        libtinfo-dev \
        pkg-config \
        texinfo \
        wget \
        zlib1g-dev \
    && unlink /usr/bin/gcc \
    && ln -s /usr/bin/gcc-14 /usr/bin/gcc \
    && rm -rf /var/lib/apt/lists/*

# TOML install (L7-L14): build Emacs from the GNU source tarball.
# Upstream does not publish a checksum file, so the sha256 is pinned via
# ARG and verified before extraction. `-j$(nproc)` is added for build
# speed (no semantic change to the produced binary).
RUN cd /tmp \
    && wget -q "https://ftp.gnu.org/gnu/emacs/emacs-${EMACS_VERSION}.tar.gz" \
    && echo "${EMACS_SHA256}  emacs-${EMACS_VERSION}.tar.gz" | sha256sum -c - \
    && tar xf "emacs-${EMACS_VERSION}.tar.gz" \
    && cd "emacs-${EMACS_VERSION}" \
    && ./configure --with-native-compilation \
    && make -j"$(nproc)" bootstrap NATIVE_FULL_AOT=1 \
    && make install \
    && cd / \
    && rm -rf "/tmp/emacs-${EMACS_VERSION}" "/tmp/emacs-${EMACS_VERSION}.tar.gz"

# TOML install (L16-L25): install MELPA libraries (dash, ht, recur, s) and
# pre-compile the bundled .el files. MELPA is HEAD-only; the TOML does not
# pin versions either, so we mirror the same "install latest at build
# time" behaviour. `~/.emacs.d/elpa/**/*.el` requires bash globstar; the
# default Dockerfile shell (/bin/sh -> dash) does not expand `**`, so the
# byte-/native-compile commands are wrapped in `bash -O globstar -c`.
RUN emacs --batch --eval "\
(progn \
  (package-initialize) \
  (add-to-list 'package-archives '(\"melpa\" . \"https://melpa.org/packages/\") t) \
  (package-refresh-contents) \
  (mapc #'package-install \
        '(dash \
          ht \
          recur \
          s)))" \
    && bash -O globstar -c 'emacs --batch --eval "(package-initialize)" -f batch-byte-compile ~/.emacs.d/elpa/**/*.el' \
    && bash -O globstar -c 'emacs --batch --eval "(package-initialize)" -f batch-native-compile ~/.emacs.d/elpa/**/*.el'

# Smoke test (added beyond the TOML): mirror the TOML's compile + execute
# sections — native-compile `Main.el` to `Main.eln`, run via `-l Main.eln`,
# and confirm stdout. Catches regressions in libgccjit / native-comp
# wiring before the image ships.
RUN printf '(princ "Hello, Emacs Lisp!\\n")\n' > Main.el \
    && emacs --batch -f package-initialize \
        --eval '(native-compile "Main.el" (expand-file-name "Main.eln"))' \
    && out="$(emacs --batch -f package-initialize -l Main.eln 2>/dev/null)" \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "Hello, Emacs Lisp!" \
    && rm -f Main.el Main.eln

# TOML install (L27-L28): purge >=1MB build-only deps to shrink the image.
# `libgnutls28-dev` is removed but the runtime `libgnutls30` stays; Emacs
# links against the runtime lib, so this is safe.
RUN apt-get purge -y autoconf libgnutls28-dev texinfo \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
