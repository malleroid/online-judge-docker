# online-judge-docker

Competitive programming judge environments as Docker images.

Reproduce the exact judge environment locally so you can compile and test your solutions before submitting.

## Supported Judges

### AtCoder (2025/10)

| Language | Image |
|---|---|
| Go (go 1.25.1) | `ghcr.io/malleroid/online-judge-docker/atcoder-go:2025.10` |
| Rust (rustc 1.89.0) | `ghcr.io/malleroid/online-judge-docker/atcoder-rust:2025.10` |
| Zig (Zig 0.15.1) | `ghcr.io/malleroid/online-judge-docker/atcoder-zig:2025.10` |

> More languages coming soon (C++, Python, PyPy, Ruby, ...).

## Usage

Add a `compose.yaml` to your solutions repository:

```yaml
services:
  go:
    image: ghcr.io/malleroid/online-judge-docker/atcoder-go:2025.10
    volumes:
      - ./main.go:/judge/main.go
    working_dir: /judge
  rust:
    image: ghcr.io/malleroid/online-judge-docker/atcoder-rust:2025.10
    volumes:
      - ./main.rs:/judge/src/main.rs
    working_dir: /judge
```

```bash
# Go
docker compose run --rm go go build -o a.out && docker compose run --rm go ./a.out

# Rust
docker compose run --rm rust cargo build --release --quiet --offline
docker compose run --rm rust ./target/release/main < input.txt
```

### Zig notes

- 4 libraries pre-installed (ac-library-zig, proconio-zig, zig-string, mvzr)
- Build with `zig build --release -Doptimize=ReleaseFast`, output at `zig-out/bin/judge`
- `build.zig` and `build.zig.zon` are pre-configured in `/judge`

### Go notes

- 6 libraries pre-installed (gods, gonum, gostl, immutable, x/exp, ac-library-go)
- `go.mod` and `go.sum` are pre-configured in `/judge`

### Rust notes

- All 67 official crates are pre-built in the image (proconio, itertools, etc.)
- `--offline` works because all dependencies are pre-compiled
- `#[cfg(atcoder)]` is enabled via `.cargo/config.toml`

## Architecture

Images are provided for `linux/amd64` and `linux/arm64`.

The AtCoder judge runs on x86_64. The arm64 variant is provided for local development convenience on Apple Silicon Macs.

## License

[MIT](LICENSE)
