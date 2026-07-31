@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\check_setup.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%
