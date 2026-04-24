FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ARG TARGETARCH
ARG GO_VERSION=1.25.1

WORKDIR /judge

# Install wget for downloading Go
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

# Install Go from official binary
# AtCoder judge runs on x86_64; arm64 is provided for local development convenience
RUN GO_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") \
    && wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz \
    && tar -C /opt -xf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

ENV PATH="/opt/go/bin:${PATH}"

# Initialize module and install libraries
RUN go mod init atcoder.jp/golang \
    && go get \
        github.com/emirpasic/gods \
        gonum.org/v1/gonum \
        github.com/liyue201/gostl \
        github.com/benbjohnson/immutable \
        golang.org/x/exp \
        github.com/monkukui/ac-library-go
