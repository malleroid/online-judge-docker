# online-judge-docker

Competitive programming judge environments as Docker images.

Reproduce the exact judge environment locally so you can compile and test your solutions before submitting.

## Supported Judges

- [AtCoder (2025/10)](docs/atcoder.md) — 116 languages

## Usage

Add a `compose.yaml` to your solutions repository, listing the languages you want. The service name is arbitrary; the `image` tag comes from the per-judge documentation linked above; mount your source file into `/judge`:

```yaml
services:
  <service-name>:
    image: ghcr.io/malleroid/online-judge-docker/<image>:<judge-version>
    volumes:
      - ./<source>:/judge/<source>
    working_dir: /judge
    # Required for amd64-only images (marked `*` in the per-judge table)
    # platform: linux/amd64
```

Then `docker compose run --rm <service-name> <command>` to compile/run. The compile/run command for each image matches the upstream judge's language manifest verbatim — refer to the per-judge documentation for the manifest URL.

## Architecture

Most images are multi-arch (`linux/amd64` + `linux/arm64`). Images marked with `*` in each judge's table are amd64 only — typically because upstream only ships x86_64 binaries or the implementation has architecture-specific code paths.

Judges themselves run on amd64 hardware. The arm64 variant (where available) is provided for local development convenience on Apple Silicon Macs.

## License

[MIT](LICENSE)
