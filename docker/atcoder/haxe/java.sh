#!/bin/sh
if [ "$1" -gt 1024 ]; then
    stack_size=1024
else
    stack_size="$1"
fi
java -jar -Xss"$stack_size"M Main.jar
