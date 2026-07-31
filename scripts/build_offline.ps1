$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDirectory = Join-Path $ProjectRoot "bin"
$OutputFile = Join-Path $OutputDirectory "error-explainer.exe"
$gcc = Find-Gcc

if ($null -eq $gcc) {
    Write-Host "GCC was not found." -ForegroundColor Red
    Write-Host "Run: gcc --version"
    Write-Host "Expected MSYS2 path: C:\msys64\ucrt64\bin\gcc.exe"
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$sources = @(
    (Join-Path $ProjectRoot "src\main.c"),
    (Join-Path $ProjectRoot "src\compiler.c"),
    (Join-Path $ProjectRoot "src\explainer.c")
)

Write-Host "Using GCC: $gcc"
Write-Host "Building the offline error explainer..."

& $gcc -std=c11 -g -O0 -Wall -Wextra -Wpedantic -fdiagnostics-color=never @sources -o $OutputFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Build successful: $OutputFile" -ForegroundColor Green
exit 0
