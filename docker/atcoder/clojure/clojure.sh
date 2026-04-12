#!/bin/sh
if [ "$1" -gt 1024 ]; then
  stack_size=1024
else
  stack_size="$1"
fi

heap_size=$(($1 * 90 / 100))

clojure -J-Xss"$stack_size"M -J-Xmx"$heap_size"M -A:ac -M Main.clj
