#!/usr/bin/env bash

set -euo pipefail

UV="{{uv}}"
RESOLVED_PYTHON="{{resolved_python}}"
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"

RESOLVED_PYTHON_BIN="$(dirname "$RESOLVED_PYTHON")"

# set resolved python to front of the path
export PATH="$RESOLVED_PYTHON_BIN:$PATH"

# get the version of python to hand to uv pip compile
PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

$UV pip compile \
    --generate-hashes \
    --no-header \
    --python-version=$PYTHON_VERSION \
    -o $REQUIREMENTS_TXT \
    $REQUIREMENTS_IN \
    $@
