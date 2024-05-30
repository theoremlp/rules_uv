#!/usr/bin/env bash

set -euo pipefail

# inputs from Bazel
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"
COMPILE_COMMAND="{{compile_command}}"

# set resolved python to front of the path
RESOLVED_PYTHON_BIN="$(dirname "{{resolved_python}}")"
export PATH="$RESOLVED_PYTHON_BIN:$PATH"

# make a writable copy of incoming requirements
cp "$REQUIREMENTS_TXT" __updated__
  
{{uv}} pip compile \
    --quiet \
    --no-cache \
    {{args}} \
    --output-file="__updated__" \
    "$REQUIREMENTS_IN"

# check files match
DIFF="$(diff "$REQUIREMENTS_TXT" "__updated__" || true)"
if [ "$DIFF" != "" ]
then
  echo >&2 "FAIL: $REQUIREMENTS_TXT is out-of-date. Run '$COMPILE_COMMAND' to update."
  echo >&2 "$DIFF"
  exit 1
fi
