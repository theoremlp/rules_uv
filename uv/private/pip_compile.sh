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

$UV pip compile \
    --generate-hashes \
    --emit-index-url \
    --no-strip-extras \
    --custom-compile-command "bazel run $LABEL" \
    --python-version="$PYTHON_VERSION" \
    $(echo $PYTHON_PLATFORM) \
    -o "$REQUIREMENTS_TXT" \
    "$REQUIREMENTS_IN" \
    {{extra_arguments}} "$@"
