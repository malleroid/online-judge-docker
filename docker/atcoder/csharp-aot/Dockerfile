FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG DOTNET_SDK_VERSION=9.0.304

# RuntimeIdentifier=linux-x64 is hardcoded in csproj; amd64 only
# Build with: docker build --platform linux/amd64

ENV HOME=/root
ENV DOTNET_ROOT="${HOME}/.dotnet"
ENV PATH="${DOTNET_ROOT}:${DOTNET_ROOT}/tools:${PATH}"
ENV DOTNET_EnableWriteXorExecute=0
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

WORKDIR /judge

# Install .NET SDK dependencies + clang (AOT linker) + zlib1g-dev (native compile)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates clang libc6 libgcc-s1 libgssapi-krb5-2 libicu74 \
        liblttng-ust1 libssl3 libstdc++6 libunwind8 wget zlib1g zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN wget -qO- https://dot.net/v1/dotnet-install.sh | bash -s -- --version ${DOTNET_SDK_VERSION}

# Copy project files
COPY Main.csproj Main.csproj
COPY packages.lock.json packages.lock.json

# Restore and pre-compile (AOT)
RUN echo 'Console.WriteLine("Hello, world!");' > Main.cs \
    && dotnet publish -c Release -o publish -v n \
    && rm publish/Main \
    && rm Main.cs
