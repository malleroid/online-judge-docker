FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

ARG SCALA_VERSION=3.7.2
ARG ACLIB_COMMIT=050a967

# scala-cli apt package is amd64 only; no arm64 support
# Build with: docker build --platform linux/amd64

WORKDIR /judge

# Add scala-cli and sbt repositories
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg wget \
    && curl -sS "https://virtuslab.github.io/scala-cli-packages/KEY.gpg" \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/scala-cli.gpg 2>/dev/null \
    && curl -s --compressed -o /etc/apt/sources.list.d/scala_cli_packages.list \
        "https://virtuslab.github.io/scala-cli-packages/debian/scala_cli_packages.list" \
    && echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" > /etc/apt/sources.list.d/sbt.list \
    && echo "deb https://repo.scala-sbt.org/scalasbt/debian /" > /etc/apt/sources.list.d/sbt_old.list \
    && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" \
        | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import \
    && chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends ansifilter openjdk-21-jdk-headless sbt scala-cli \
    && rm -rf /var/lib/apt/lists/*

# Build ac-library-scala from source
RUN wget -q -O /tmp/ac-library.tar.gz \
        "https://github.com/harry0000/ac-library-scala/archive/${ACLIB_COMMIT}.tar.gz" \
    && mkdir /tmp/ac-library \
    && tar -C /tmp/ac-library --strip-components=1 -xf /tmp/ac-library.tar.gz \
    && cd /tmp/ac-library \
    && AC_SBT_VERSION="$(dpkg-query -W -f='${Version}' sbt)" \
    && printf "sbt.version = %s\n" "$AC_SBT_VERSION" > project/build.properties \
    && sed -i "s/.*lazy val supportedScalaVersions.*/lazy val supportedScalaVersions = List(\"${SCALA_VERSION}\")/" build.sbt \
    && sbt package \
    && cd /judge \
    && mkdir -p lib \
    && cp /tmp/ac-library/target/scala-${SCALA_VERSION}/ac-library-scala_3-0.1.0-SNAPSHOT.jar lib/ac-library.jar \
    && rm -rf /tmp/ac-library*

# Pre-build with dummy source
RUN printf '//> using file "lib/ac-library.jar"\nobject Main { def main(args: Array[String]): Unit = println("Hello") }\n' > Main.scala \
    && scala-cli --power package --bloop-jvm system --jvm system -S ${SCALA_VERSION} Main.scala -o Main --assembly --quiet \
    && rm Main Main.scala

# Copy execution wrapper script
COPY scala.sh scala.sh
