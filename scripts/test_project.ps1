$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")
. (Join-Path $PSScriptRoot "analyze_common.ps1")

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$gcc = Find-Gcc

if ($null -eq $gcc) {
    Write-Host "GCC was not found." -ForegroundColor Red
    exit 1
}

$tests = @(
    @{ Name = "Missing semicolon"; File = "examples\missing_semicolon.c"; Expected = 2 },
    @{ Name = "Undeclared variable"; File = "examples\undeclared_variable.c"; Expected = 2 },
    @{ Name = "Correct program"; File = "examples\correct_program.c"; Expected = 0 },
    @{ Name = "Unused variable warning"; File = "examples\unused_variable.c"; Expected = 0 }
)

$failed = 0

foreach ($test in $tests) {
    Write-Host ""
    Write-Host "TEST: $($test.Name)" -ForegroundColor Cyan

    $source = Join-Path $ProjectRoot $test.File
    $exitCode = Invoke-Analysis -Gcc $gcc -SourcePath $source
    $actual = $exitCode

    if ($actual -eq $test.Expected) {
        Write-Host "PASS (exit code $actual)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: expected $($test.Expected), received $actual" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
if ($failed -eq 0) {
    Write-Host "All tests passed." -ForegroundColor Green
    exit 0
}

Write-Host "$failed test(s) failed." -ForegroundColor Red
exit 1
