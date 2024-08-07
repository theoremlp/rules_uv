#!/usr/bin/env bash

set -euo pipefail

# inputs from Bazel
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"
COMPILE_COMMAND="{{compile_command}}"

# make a writable copy of incoming requirements
updated_file=$(mktemp)
trap 'rm -f "$updated_file"' EXIT
cp "$REQUIREMENTS_TXT" "$updated_file"

{{uv}} pip compile \
    --quiet \
    --no-cache \
    {{args}} \
    --output-file="$updated_file" \
    "$REQUIREMENTS_IN"

# check files match
DIFF="$(diff "$REQUIREMENTS_TXT" "$updated_file" || true)"
if [ "$DIFF" != "" ]
then
  echo >&2 "FAIL: $REQUIREMENTS_TXT is out-of-date. Run '$COMPILE_COMMAND' to update."
  echo >&2 "$DIFF"
  exit 1
fi
