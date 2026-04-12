#!/bin/sh

export NODE_PATH=/usr/local/lib/node_modules
cd main

if [ "$1" -gt 1048576 ]; then
  stack_size=1048576
else
  stack_size="$1"
fi

filename="$2"

node \
  -r source-map-support/register \
  --stack-size="$stack_size" \
  "$filename"
