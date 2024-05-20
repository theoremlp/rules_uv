#!/usr/bin/env bash

set -euo pipefail

UV="{{uv}}"
PYTHON_PLATFORM="{{python_platform}}"
RESOLVED_PYTHON="{{resolved_python}}"
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"

RESOLVED_PYTHON_BIN="$(dirname "$RESOLVED_PYTHON")"

# set resolved python to front of the path
export PATH="$RESOLVED_PYTHON_BIN:$PATH"

# get the version of python to hand to uv pip compile
PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

$UV pip compile \
    --no-cache \
    --generate-hashes \
    --emit-index-url \
    --no-header \
    --no-strip-extras \
    --python-version=$PYTHON_VERSION \
    $(echo $PYTHON_PLATFORM) \
    -c $REQUIREMENTS_TXT \
    $REQUIREMENTS_IN
