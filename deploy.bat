@echo off
REM Double-click launcher: clear cache, render both reports, commit, push to GitHub.
REM Vercel auto-deploys on push.

setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1"
set EXITCODE=%ERRORLEVEL%

echo.
if %EXITCODE% NEQ 0 (
    echo Deploy FAILED with exit code %EXITCODE%.
) else (
    echo Deploy complete - Vercel will finish within ~30s.
)

echo.
pause
exit /b %EXITCODE%
