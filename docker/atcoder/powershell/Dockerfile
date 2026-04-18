FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

ARG TARGETARCH
ARG PWSH_VERSION=7.5.2
ARG ACLIB_VERSION=3.9.2-atcoder1

ENV HOME=/root
ENV DOTNET_EnableWriteXorExecute=0

WORKDIR /judge

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libicu74 unzip wget \
    && rm -rf /var/lib/apt/lists/*

# Install ac-library-csharp DLL
RUN wget -q "https://github.com/kzrnm/ac-library-csharp/releases/download/v${ACLIB_VERSION}/ac-library-csharp.${ACLIB_VERSION}.nupkg" \
        -O /tmp/aclib.nupkg \
    && unzip -q /tmp/aclib.nupkg -d /tmp/aclib \
    && mv /tmp/aclib/lib/net9.0/ac-library-csharp.dll /judge/ \
    && rm -rf /tmp/aclib /tmp/aclib.nupkg

# Install PowerShell
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN PWSH_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") \
    && wget -q "https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-${PWSH_ARCH}.tar.gz" \
        -O /tmp/pwsh.tar.gz \
    && mkdir -p ${HOME}/.powershell \
    && tar xzf /tmp/pwsh.tar.gz -C ${HOME}/.powershell \
    && ln -s ${HOME}/.powershell/pwsh /usr/local/bin/pwsh \
    && chmod +x /usr/local/bin/pwsh \
    && rm /tmp/pwsh.tar.gz
