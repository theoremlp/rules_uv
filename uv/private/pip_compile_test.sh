#!/usr/bin/env bash

set -euo pipefail

UV="{{uv}}"
PYTHON_PLATFORM="{{python_platform}}"
RESOLVED_PYTHON="{{resolved_python}}"
PYTHON_VERSION="{{python_version}}"
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"
LABEL="{{label}}"

RESOLVED_PYTHON_BIN="$(dirname "$RESOLVED_PYTHON")"

# set resolved python to front of the path
export PATH="$RESOLVED_PYTHON_BIN:$PATH"

# make a writable copy of incoming requirements
cp "$REQUIREMENTS_TXT" __updated__

$UV pip compile \
    --quiet \
    --no-cache \
    --generate-hashes \
    --emit-index-url \
    --no-strip-extras \
    --custom-compile-command "bazel run ${LABEL}" \
    --python-version="$PYTHON_VERSION" \
    $(echo $PYTHON_PLATFORM) \
    -o __updated__ \
    "$REQUIREMENTS_IN"

# check files match
DIFF="$(diff "$REQUIREMENTS_TXT" "__updated__" || true)"
if [ "$DIFF" != "" ]
then
  echo >&2 "FAIL: $REQUIREMENTS_TXT is out-of-date. Run 'bazel run $LABEL' to update."
  echo >&2 "$DIFF"
  exit 1
fi
