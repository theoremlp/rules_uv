#!/usr/bin/env bash

set -euo pipefail

UV="{{uv}}"
PYTHON_PLATFORM="{{python_platform}}"
RESOLVED_PYTHON="{{resolved_python}}"
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"
LABEL="{{label}}"
PIP_COMPILE_ARGS='{{pip_compile_args}}'

RESOLVED_PYTHON_BIN="$(dirname "$RESOLVED_PYTHON")"

# set resolved python to front of the path
export PATH="$RESOLVED_PYTHON_BIN:$PATH"

# get the version of python to hand to uv pip compile
PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

eval $UV pip compile \
    $PIP_COMPILE_ARGS \
    $(echo $PYTHON_PLATFORM) \
    -o $REQUIREMENTS_TXT \
    $REQUIREMENTS_IN \
    "$@"
