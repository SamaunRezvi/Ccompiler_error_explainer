$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "common.ps1")

$gcc = Find-Gcc
$gdb = Find-Gdb

Write-Host "AI Compiler Error Explainer - Setup Check" -ForegroundColor Cyan
Write-Host ""

if ($null -ne $gcc) {
    Write-Host "[OK] GCC: $gcc" -ForegroundColor Green
    & $gcc --version | Select-Object -First 1
} else {
    Write-Host "[MISSING] GCC" -ForegroundColor Red
}

Write-Host ""
if ($null -ne $gdb) {
    Write-Host "[OK] GDB: $gdb" -ForegroundColor Green
    & $gdb --version | Select-Object -First 1
} else {
    Write-Host "[OPTIONAL] GDB was not found. Normal runs will work, but F5 debugging may not work." -ForegroundColor Yellow
}

Write-Host ""
if ($null -eq $gcc) {
    Write-Host "Install GCC from an MSYS2 UCRT64 terminal:" -ForegroundColor Yellow
    Write-Host "pacman -Syu"
    Write-Host "pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-gdb"
    Write-Host ""
    Write-Host "Then add this directory to the Windows PATH and restart VS Code:"
    Write-Host "C:\msys64\ucrt64\bin"
    exit 1
}

Write-Host "Setup is ready." -ForegroundColor Green
exit 0
