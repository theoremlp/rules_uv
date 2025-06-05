#!/usr/bin/env bash

set -euo pipefail

# inputs from Bazel
PYPROJECT_TOML="{{pyproject_toml}}"
REQUIREMENTS_TXT="{{requirements_txt}}"

{{uv}} export \
    {{args}} \
    --output-file="$REQUIREMENTS_TXT" \
    "$@"
