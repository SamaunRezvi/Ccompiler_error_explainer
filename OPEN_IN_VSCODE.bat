@echo off
cd /d "%~dp0"
where code >nul 2>nul
if %ERRORLEVEL% equ 0 (
    code "AI-Compiler-Error-Explainer.code-workspace"
) else (
    start "" "AI-Compiler-Error-Explainer.code-workspace"
)
