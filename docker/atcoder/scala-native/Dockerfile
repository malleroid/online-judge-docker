FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG SCALA_VERSION=3.7.2
ARG SCALA_NATIVE_VERSION=0.5.8
ARG SBT_VERSION=1.11.7
ARG ACLIB_COMMIT=050a967

ARG SBT_SHA256=1232818f91c39639a93bbe1108e12d94c7044a646a7847f1a3977b9e46716cd6

WORKDIR /judge

# OpenJDK 21 runs sbt, clang/libstdc++-12-dev are the Scala Native LLVM
# backend toolchain. The TOML's install step also pulls sbt from the
# scala-sbt.org APT repository; we swap in the upstream GitHub Release
# tarball (sha256 pinned) to match docker/atcoder/scala/Dockerfile and
# avoid the third-party APT rotation risk documented in CLAUDE.md.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        curl \
        libstdc++-12-dev \
        openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/sbt.tgz \
        "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
    && echo "${SBT_SHA256}  /tmp/sbt.tgz" | sha256sum -c - \
    && tar -C /opt -xzf /tmp/sbt.tgz \
    && ln -s /opt/sbt/bin/sbt /usr/local/bin/sbt \
    && rm /tmp/sbt.tgz

# Create the main/ project skeleton exactly as the TOML install step
# does: a build.sbt enabling ScalaNativePlugin with releaseFast mode,
# project/plugins.sbt adding sbt-scala-native, project/build.properties
# pinning sbt.version, and src/main/scala/Main.scala using the TOML's
# ac-library Dsu probe. SBT_VERSION is a Docker ARG (vs. the TOML's
# `dpkg-query -W sbt`) because we install sbt via tarball.
RUN set -eu; \
    mkdir -p main/project main/src/main/scala main/lib \
    && { \
        echo 'import scala.scalanative.build._'; \
        echo ''; \
        echo "scalaVersion := \"${SCALA_VERSION}\""; \
        echo ''; \
        echo 'enablePlugins(ScalaNativePlugin)'; \
        echo ''; \
        echo 'nativeConfig ~= {'; \
        echo '    _.withMode(Mode.releaseFast)'; \
        echo '}'; \
        echo ''; \
        echo 'Compile / unmanagedJars += baseDirectory.value / "lib/ac-library-scala_native0.5_3-0.1.0-SNAPSHOT.jar"'; \
    } > main/build.sbt \
    && printf 'addSbtPlugin("org.scala-native" %% "sbt-scala-native" %% "%s")\n' "${SCALA_NATIVE_VERSION}" > main/project/plugins.sbt \
    && printf 'sbt.version = %s\n' "${SBT_VERSION}" > main/project/build.properties \
    && { \
        echo 'import io.github.acl4s.Dsu'; \
        echo ''; \
        echo 'object Main {'; \
        echo '  def main(args: Array[String]): Unit ='; \
        echo '    val uf = Dsu(10)'; \
        echo '    uf.merge(1, 3)'; \
        echo '    uf.merge(3, 7)'; \
        echo '    println(uf.groups())'; \
        echo '    println("Hello, world!")'; \
        echo '}'; \
    } > main/src/main/scala/Main.scala

# Build ac-library-scala for Scala Native: fetch the TOML-pinned commit,
# add the sbt-scala-native plugin + sbt pin, then sed-inject the Scala
# Native imports and releaseFull mode into build.sbt (pattern preserved
# verbatim from the TOML, which replaces the `lazy val
# supportedScalaVersions` line with a multi-line block). `sbt package`
# produces the Scala Native variant of the jar, which we copy into
# main/lib/ so the TOML's `Compile / unmanagedJars` wiring picks it up.
RUN curl -fsSL -o /tmp/ac-library.tar.gz \
        "https://github.com/harry0000/ac-library-scala/archive/${ACLIB_COMMIT}.tar.gz" \
    && mkdir /tmp/ac-library \
    && tar -C /tmp/ac-library --strip-components=1 -xf /tmp/ac-library.tar.gz \
    && cd /tmp/ac-library \
    && printf 'addSbtPlugin("org.scala-native" %% "sbt-scala-native" %% "%s")\n' "${SCALA_NATIVE_VERSION}" >> project/plugins.sbt \
    && printf 'sbt.version = %s\n' "${SBT_VERSION}" > project/build.properties \
    && sed -i "s/.*lazy val supportedScalaVersions.*/import scala.scalanative.build._\n\nlazy val supportedScalaVersions = List(\"${SCALA_VERSION}\")\nenablePlugins(ScalaNativePlugin)\nnativeConfig ~= {\n    _.withMode(Mode.releaseFull)\n}/" build.sbt \
    && sbt package \
    && cp "target/scala-${SCALA_VERSION}/ac-library-scala_native0.5_3-0.1.0-SNAPSHOT.jar" /judge/main/lib/ \
    && rm -rf /tmp/ac-library*

# Smoke test + offline cache warmup: running `sbt nativeLink` here
# downloads the sbt-scala-native plugin, the Scala Native runtime
# modules (nativelib/clib/posixlib/javalib), and compiles Immix GC
# prebuilt objects under ~/.cache/coursier and ~/.sbt. The judge then
# runs `sbt -error "set offline := true" nativeLink` (per the TOML
# compile command) which resolves entirely from that cache. Execute the
# produced binary once to assert the ac-library Dsu path links and
# runs, then delete it — the judge recompiles from Main.scala each
# submission.
RUN cd main \
    && sbt nativeLink \
    && out="$(target/scala-${SCALA_VERSION}/main)" \
    && echo "smoke-test output:" \
    && printf '%s\n' "$out" \
    && echo "$out" | grep -q "Hello, world!" \
    && rm -f "target/scala-${SCALA_VERSION}/main"
