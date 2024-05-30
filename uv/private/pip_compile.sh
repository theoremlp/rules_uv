#!/usr/bin/env bash

set -euo pipefail

# inputs from Bazel
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"

# set resolved python to front of the path
RESOLVED_PYTHON_BIN="$(dirname "{{resolved_python}}")"
export PATH="$RESOLVED_PYTHON_BIN:$PATH"

{{uv}} pip compile \
    {{args}} \
    --output-file="$REQUIREMENTS_TXT" \
    "$REQUIREMENTS_IN" \
    "$@"
