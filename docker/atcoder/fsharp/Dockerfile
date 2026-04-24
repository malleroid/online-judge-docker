FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG DOTNET_SDK_VERSION=9.0.304

# RuntimeIdentifier=linux-x64 is hardcoded in fsproj; amd64 only
# Build with: docker build --platform linux/amd64

ENV HOME=/root
ENV DOTNET_ROOT="${HOME}/.dotnet"
ENV PATH="${DOTNET_ROOT}:${DOTNET_ROOT}/tools:${PATH}"
ENV DOTNET_EnableWriteXorExecute=0
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

WORKDIR /judge

# Install .NET SDK dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates libc6 libgcc-s1 libgssapi-krb5-2 libicu74 \
        liblttng-ust1 libssl3 libstdc++6 libunwind8 wget zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN wget -qO- https://dot.net/v1/dotnet-install.sh | bash -s -- --version ${DOTNET_SDK_VERSION}

# Copy project files
COPY Main.fsproj Main.fsproj
COPY packages.lock.json packages.lock.json

# Restore and pre-compile
RUN echo 'stdout.WriteLine "Hello, world!"' > Main.fs \
    && dotnet publish -c Release -o publish -v n \
    && rm publish/Main \
    && rm Main.fs
