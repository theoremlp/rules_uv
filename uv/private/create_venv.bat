@REM @echo off
setlocal enabledelayedexpansion

set "UV={{uv}}"
set "RESOLVED_PYTHON={{resolved_python}}"
set "REQUIREMENTS_TXT={{requirements_txt}}"

for %%f in ("%RESOLVED_PYTHON%") do set "PYTHON=%%~ff"

if "%~1"=="" (
  set "target={{destination_folder}}"
) else (
  set "target=%~1"
)

if "%target%"=="." (
  echo Invalid target '%target%'
  exit /b -1
)

set "BUILD_WORKSPACE_WINDOWS=%BUILD_WORKSPACE_DIRECTORY:/=\%"

%UV% venv "%BUILD_WORKSPACE_WINDOWS%\%target%" --python "%PYTHON%"
call "%BUILD_WORKSPACE_WINDOWS%\%target%\Scripts\activate"
%UV% pip install -r "%REQUIREMENTS_TXT%"
echo %CD%
set site_packages_extra_files={{site_packages_extra_files}}
if defined site_packages_extra_files (
  for /d %%d in ("%BUILD_WORKSPACE_WINDOWS%\%target%\Lib\site-packages") do (
    for %%f in (%site_packages_extra_files%) do (
      copy %%f %%d
    )
  )
)

echo Created '%target%', to activate run:
echo   call "%target%\Scripts\activate"