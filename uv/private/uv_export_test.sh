#!/usr/bin/env bash

set -euo pipefail

# inputs from Bazel
PYPROJECT_TOML="{{pyproject_toml}}"
REQUIREMENTS_TXT="{{requirements_txt}}"
COMPILE_COMMAND="{{compile_command}}"

# make a writable copy of incoming requirements
updated_file=$(mktemp)
trap 'rm -f "$updated_file"' EXIT
cp "$REQUIREMENTS_TXT" "$updated_file"

{{uv}} export \
    --quiet \
    --no-cache \
    {{args}} \
    --output-file="$updated_file"

# check files match
DIFF="$(diff -I '^#[[:space:]]*uv export' "$REQUIREMENTS_TXT" "$updated_file" || true)"
if [ "$DIFF" != "" ]
then
  echo >&2 "FAIL: $REQUIREMENTS_TXT is out-of-date. Run '$COMPILE_COMMAND' to update."
  echo >&2 "$DIFF"
  exit 1
fi
