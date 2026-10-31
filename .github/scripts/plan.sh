#!/usr/bin/env bash
# Reads paths under docker/ (files or image dirs, one per line) from stdin and
# prints the build/publish matrices as GITHUB_OUTPUT lines.
# Requires JUDGE_VERSIONS: JSON map of judge name to image tag.
set -euo pipefail

rows=$(
  sed 's|^\(docker/[^/]*/[^/]*\)/.*|\1|' | sort -u | while read -r dir; do
    [ -f "$dir/Dockerfile" ] || continue
    judge=$(cut -d/ -f2 <<<"$dir")
    lang=$(cut -d/ -f3 <<<"$dir")
    platforms=$(sed -n 's/^# platforms: *//p' "$dir/Dockerfile" | head -n 1)
    for platform in ${platforms:-linux/amd64 linux/arm64}; do
      printf '%s\t%s\t%s\t%s\n' "$dir" "$judge" "$lang" "$platform"
    done
  done
)

jq -Rnr --argjson versions "$JUDGE_VERSIONS" '
  def runner:
    {amd64: "ubuntu-latest", arm64: "ubuntu-26.04-arm"}[.arch]
    // error("Unsupported platform \(.platform) in \(.dir)");
  def tag:
    $versions[.judge]
    // error("No version defined for judge \(.judge) in JUDGE_VERSIONS");

  [ inputs
    | select(length > 0)
    | split("\t")
    | {dir: .[0], judge: .[1], image: "\(.[1])-\(.[2])", platform: .[3], arch: (.[3] | ltrimstr("linux/"))}
    | .runner = runner
    | .tag = tag
  ] as $builds
  | "builds=\($builds | map({dir, image, platform, arch, runner}) | tojson)",
    "images=\($builds | group_by(.image) | map({image: .[0].image, tag: .[0].tag, platform_count: length}) | tojson)"
' <<<"$rows"
