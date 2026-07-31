$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")
. (Join-Path $PSScriptRoot "analyze_common.ps1")

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SourceFile = Join-Path $ProjectRoot "playground\user_code.c"
$gcc = Find-Gcc

if ($null -eq $gcc) {
    Write-Host "GCC was not found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Analyzing playground\user_code.c..." -ForegroundColor Cyan

$exitCode = Invoke-Analysis -Gcc $gcc -SourcePath $SourceFile

# Exit code 2 means the target C file contains a compiler error.
# That is an expected result for an error-explainer tool.
if ($exitCode -eq 0 -or $exitCode -eq 2) {
    exit 0
}

exit $exitCode
