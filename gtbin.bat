@echo off
setlocal

:: Install GTB Agent
msiexec /quiet /i "C:\ReceivedFiles1\GTB\GTB.msi"

:: Check if the installation was successful
if %errorlevel% equ 0 (
    echo Installation was successful.
) else (
    echo Installation failed with error code %errorlevel%.
)

endlocal
pause
