# online-judge-docker

Competitive programming judge environments as Docker images.

Reproduce the exact judge environment locally so you can compile and test your solutions before submitting.

## Supported Judges

### AtCoder (2025/10)

| Language | Image |
|---|---|
| AWK (GNU awk 5.2.1) | `ghcr.io/malleroid/online-judge-docker/atcoder-awk:2025.10` |
| Bash (bash 5.3) | `ghcr.io/malleroid/online-judge-docker/atcoder-bash:2025.10` |
| bc (GNU bc 1.08.2) | `ghcr.io/malleroid/online-judge-docker/atcoder-bc:2025.10` |
| Dart (Dart 3.9.2) | `ghcr.io/malleroid/online-judge-docker/atcoder-dart:2025.10` |
| dc 1.5.2 (GNU bc 1.08.2) | `ghcr.io/malleroid/online-judge-docker/atcoder-dc:2025.10` |
| Forth (gforth 0.7.3) | `ghcr.io/malleroid/online-judge-docker/atcoder-forth:2025.10` |
| JavaScript (Bun 1.2.21) | `ghcr.io/malleroid/online-judge-docker/atcoder-bun:2025.10` |
| Julia (Julia 1.11.6) | `ghcr.io/malleroid/online-judge-docker/atcoder-julia:2025.10` |
| JavaScript (Deno 2.4.5) | `ghcr.io/malleroid/online-judge-docker/atcoder-deno:2025.10` |
| Go (go 1.25.1) | `ghcr.io/malleroid/online-judge-docker/atcoder-go:2025.10` |
| JavaScript (Node.js 22.19.0) | `ghcr.io/malleroid/online-judge-docker/atcoder-nodejs:2025.10` |
| Perl (perl 5.38.2) | `ghcr.io/malleroid/online-judge-docker/atcoder-perl:2025.10` |
| Rust (rustc 1.89.0) | `ghcr.io/malleroid/online-judge-docker/atcoder-rust:2025.10` |
| Text (cat 9.4) | `ghcr.io/malleroid/online-judge-docker/atcoder-text:2025.10` |
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

### Bun notes

- 6 npm libraries pre-installed (ac-library-js, data-structure-typed, immutable, lodash, mathjs, tstl)
- No compile step; runs directly with `bun Main.js --no-install`

### Deno notes

- 41 Deno standard library packages (@std/*) and 6 npm libraries pre-installed
- `deno.sh` wrapper script limits V8 stack size and passes `ONLINE_JUDGE ATCODER` args

### Node.js notes

- 6 npm libraries pre-installed globally (ac-library-js, data-structure-typed, immutable, lodash, mathjs, tstl)
- `node.sh` wrapper script limits stack size based on problem memory limit

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
