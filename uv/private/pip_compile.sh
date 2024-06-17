#!/usr/bin/env bash

set -euo pipefail

# inputs from Bazel
REQUIREMENTS_IN="{{requirements_in}}"
REQUIREMENTS_TXT="{{requirements_txt}}"

{{uv}} pip compile \
    {{args}} \
    --output-file="$REQUIREMENTS_TXT" \
    "$REQUIREMENTS_IN" \
    "$@"
