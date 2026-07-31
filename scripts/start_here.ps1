$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$RunScript = Join-Path $PSScriptRoot "run_playground.ps1"
$gcc = Find-Gcc

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " AI Compiler Error Explainer" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

if ($null -eq $gcc) {
    Write-Host "[MISSING] GCC was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install GCC from an MSYS2 UCRT64 terminal:" -ForegroundColor Yellow
    Write-Host "pacman -Syu"
    Write-Host "pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-gdb"
    Write-Host ""
    Write-Host "Then add C:\msys64\ucrt64\bin to PATH and restart VS Code."
    exit 1
}

Write-Host "[OK] GCC found: $gcc" -ForegroundColor Green
& $gcc --version | Select-Object -First 1

& $RunScript
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "Done. Edit playground\user_code.c and press Ctrl+Shift+B to analyze it again." -ForegroundColor Green
}

exit $exitCode
