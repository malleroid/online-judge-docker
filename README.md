# online-judge-docker

Competitive programming judge environments as Docker images.

Reproduce the exact judge environment locally so you can compile and test your solutions before submitting.

## Supported Judges

### AtCoder (2025/10)

| Language | Image |
|---|---|
| Rust (rustc 1.89.0) | `ghcr.io/malleroid/online-judge-docker/atcoder-rust:2025.10` |

> More languages coming soon (C++, Python, PyPy, Ruby, ...).

## Usage

Add a `compose.yaml` to your solutions repository:

```yaml
services:
  rust:
    image: ghcr.io/malleroid/online-judge-docker/atcoder-rust:2025.10
    volumes:
      - ./main.rs:/judge/src/main.rs
    working_dir: /judge
```

```bash
# Compile and run
docker compose run --rm rust cargo build --release --quiet --offline
docker compose run --rm rust ./target/release/main < input.txt
```

### Rust notes

- All 67 official crates are pre-built in the image (proconio, itertools, etc.)
- `--offline` works because all dependencies are pre-compiled
- `#[cfg(atcoder)]` is enabled via `.cargo/config.toml`

## Architecture

Images are provided for `linux/amd64` and `linux/arm64`.

The AtCoder judge runs on x86_64. The arm64 variant is provided for local development convenience on Apple Silicon Macs.

## License

[MIT](LICENSE)
