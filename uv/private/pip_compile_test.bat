@echo off
setlocal enabledelayedexpansion

REM Inputs from Bazel
set "REQUIREMENTS_IN={{requirements_in}}"
set "REQUIREMENTS_TXT={{requirements_txt}}"
set "COMPILE_COMMAND={{compile_command}}"

REM Create a temporary file
set "updated_file=%TEMP%\updated_requirements.txt"

REM Copy the original requirements file to the temporary file
copy "%REQUIREMENTS_TXT%" "%updated_file%" >nul

REM Run pip-compile command
{{uv}} pip compile ^
    --quiet ^
    --no-cache ^
    {{args}} ^
    --output-file="%updated_file%" ^
    "%REQUIREMENTS_IN%"

REM Check if the files match
fc "%REQUIREMENTS_TXT%" "%updated_file%" >nul
if not errorlevel 1 (
    REM Files match
    del "%updated_file%"
    exit /b 0
) else (
    REM Files do not match
    echo FAIL: %REQUIREMENTS_TXT% is out-of-date. Run '%COMPILE_COMMAND%' to update.
    fc "%REQUIREMENTS_TXT%" "%updated_file%"
    del "%updated_file%"
    exit /b 1
)