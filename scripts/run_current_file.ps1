param(
    [Parameter(Mandatory = $true)][string]$SourceFile
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")
. (Join-Path $PSScriptRoot "analyze_common.ps1")

if ([System.IO.Path]::GetExtension($SourceFile).ToLowerInvariant() -ne ".c") {
    Write-Host "The active file is not a .c source file: $SourceFile" -ForegroundColor Red
    exit 1
}

$gcc = Find-Gcc
if ($null -eq $gcc) {
    Write-Host "GCC was not found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Analyzing: $SourceFile" -ForegroundColor Cyan

$exitCode = Invoke-Analysis -Gcc $gcc -SourcePath $SourceFile

if ($exitCode -eq 0 -or $exitCode -eq 2) {
    exit 0
}

exit $exitCode
