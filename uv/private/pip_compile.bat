@echo off
setlocal enabledelayedexpansion

REM Inputs from Bazel
set "REQUIREMENTS_IN={{requirements_in}}"
set "REQUIREMENTS_TXT={{requirements_txt}}"

REM Run pip-compile command
{{uv}} pip compile ^
    {{args}} ^
    --output-file="%REQUIREMENTS_TXT%" ^
    "%REQUIREMENTS_IN%" ^
    %*
