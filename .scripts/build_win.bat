setlocal EnableExtensions EnableDelayedExpansion

set CONDA_BLD_PATH=C:\bld
echo "PATH is %PATH%"

rmdir /Q/S C:\Strawberry\
rmdir /Q/S "C:\Program Files (x86)\Windows Kits\10\Include\10.0.17763.0\"

set "FEEDSTOCK_ROOT=%cd%"

mkdir %CONDA_BLD_PATH%

:: Enable long path names on Windows
reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1 /f

for %%X in (%CURRENT_RECIPES%) do (
    echo "BUILDING RECIPE %%X"
    cd %FEEDSTOCK_ROOT%\recipes\%%X\
    pixi run -v rattler-build build --recipe %FEEDSTOCK_ROOT%\recipes\%%X\ ^
        -m %FEEDSTOCK_ROOT%\conda_build_config.yaml ^
        -c robostack-jazzy -c conda-forge ^
        --output-dir %CONDA_BLD_PATH%

    if errorlevel 1 exit 1
    rem -m %FEEDSTOCK_ROOT%\.ci_support\conda_forge_pinnings.yaml
)

:: Check if .conda files exist in the win-64 directory
dir /b "%CONDA_BLD_PATH%\win-64\*.conda" >nul 2>&1
if errorlevel 1 (
    :: No files found, display warning
    echo Warning: No .conda files found in %CONDA_BLD_PATH%\win-64
    echo This might be due to all the packages being skipped
) else (
    :: Files found, run the upload command
    pixi run upload "%CONDA_BLD_PATH%\win-64\*.conda" --force
    if errorlevel 1 exit 1
)
