#!/bin/sh
if [ "$1" -gt 1048576 ]; then
  stack_size=1048576
else
  stack_size="$1"
fi

deno \
run \
--allow-all \
--quiet \
--no-prompt \
--v8-flags=--stack-size="$stack_size" \
Main.ts \
ONLINE_JUDGE \
ATCODER
