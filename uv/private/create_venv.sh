#!/usr/bin/env bash

set -euo pipefail

UV="{{uv}}"
RESOLVED_PYTHON="{{resolved_python}}"
REQUIREMENTS_TXT="{{requirements_txt}}"

PYTHON="$(realpath "$RESOLVED_PYTHON")"

bold="$(tput bold)"
normal="$(tput sgr0)"

if [ $# -gt 1 ]; then
  echo "create-venv takes one optional argument, the path to the virtual environment."
  exit -1
elif [ $# == 0 ] || [ -z "$1" ]; then
  target="{{destination_folder}}"
else
  target="$1"
fi

if [ "${target}" == "/" ] || [ "${target}" == "." ]
then
  echo "${bold}Invalid venv target '${target}'${normal}"
  exit -1
fi

"$UV" venv "$BUILD_WORKSPACE_DIRECTORY/$target" --python "$PYTHON"
source "$BUILD_WORKSPACE_DIRECTORY/$target/bin/activate"
"$UV" pip install -r "$REQUIREMENTS_TXT"

site_packages_extra_files=({{site_packages_extra_files}})
site_packages_dir=$(find "$BUILD_WORKSPACE_DIRECTORY/$target/lib" -type d -name 'site-packages')
for file in "${site_packages_extra_files[@]}"; do
  cp "$file" "$site_packages_dir"/
done

echo "${bold}Created '${target}', to activate run:${normal}"
echo "  source ${target}/bin/activate"
