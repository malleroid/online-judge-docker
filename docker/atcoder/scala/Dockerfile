FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG SCALA_VERSION=3.7.2
ARG SCALA_CLI_VERSION=1.9.1
ARG SBT_VERSION=1.11.7
ARG ACLIB_COMMIT=050a967

ARG SCALA_CLI_AMD64_SHA256=fabe7085ccbdab9fd61559a3f6ff4cf5dcfe6aed72b362f2ffa4921c6119b21d
ARG SCALA_CLI_ARM64_SHA256=bf78b11d82d1eb31883c8bbe9af4539f7ad1f1503aa65569b25bad51c4f4f8d3
ARG SBT_SHA256=1232818f91c39639a93bbe1108e12d94c7044a646a7847f1a3977b9e46716cd6

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ansifilter \
        ca-certificates \
        curl \
        openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
         amd64) asset="scala-cli-x86_64-pc-linux-static.gz"; expected="${SCALA_CLI_AMD64_SHA256}" ;; \
         arm64) asset="scala-cli-aarch64-pc-linux.gz";        expected="${SCALA_CLI_ARM64_SHA256}" ;; \
         *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
       esac \
    && curl -fsSL -o /tmp/scala-cli.gz \
        "https://github.com/VirtusLab/scala-cli/releases/download/v${SCALA_CLI_VERSION}/${asset}" \
    && echo "${expected}  /tmp/scala-cli.gz" | sha256sum -c - \
    && gunzip -c /tmp/scala-cli.gz > /usr/local/bin/scala-cli \
    && chmod +x /usr/local/bin/scala-cli \
    && rm /tmp/scala-cli.gz

RUN curl -fsSL -o /tmp/sbt.tgz \
        "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
    && echo "${SBT_SHA256}  /tmp/sbt.tgz" | sha256sum -c - \
    && tar -C /opt -xzf /tmp/sbt.tgz \
    && ln -s /opt/sbt/bin/sbt /usr/local/bin/sbt \
    && rm /tmp/sbt.tgz

RUN curl -fsSL -o /tmp/ac-library.tar.gz \
        "https://github.com/harry0000/ac-library-scala/archive/${ACLIB_COMMIT}.tar.gz" \
    && mkdir /tmp/ac-library \
    && tar -C /tmp/ac-library --strip-components=1 -xf /tmp/ac-library.tar.gz \
    && cd /tmp/ac-library \
    && printf "sbt.version = %s\n" "${SBT_VERSION}" > project/build.properties \
    && sed -i "s/.*lazy val supportedScalaVersions.*/lazy val supportedScalaVersions = List(\"${SCALA_VERSION}\")/" build.sbt \
    && sbt package \
    && cd /judge \
    && mkdir -p lib \
    && cp /tmp/ac-library/target/scala-${SCALA_VERSION}/ac-library-scala_3-0.1.0-SNAPSHOT.jar lib/ac-library.jar \
    && rm -rf /tmp/ac-library*

RUN printf '//> using file "lib/ac-library.jar"\nobject Main { def main(args: Array[String]): Unit = println("Hello") }\n' > Main.scala \
    && scala-cli --power package --bloop-jvm system --jvm system -S ${SCALA_VERSION} Main.scala -o Main --assembly --quiet \
    && rm Main Main.scala

COPY scala.sh scala.sh
