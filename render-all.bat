@echo off
REM Double-click launcher: clears cache, renders both permit reports, no browser.
REM Keeps the window open at the end so you can see the result / any errors.

setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0render-all.ps1" -ClearCache -SkipOpen
set EXITCODE=%ERRORLEVEL%

echo.
if %EXITCODE% NEQ 0 (
    echo Render FAILED with exit code %EXITCODE%.
) else (
    echo Render complete.
)

echo.
pause
exit /b %EXITCODE%
