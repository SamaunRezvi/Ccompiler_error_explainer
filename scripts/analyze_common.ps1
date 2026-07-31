function Invoke-CCompilation {
    param(
        [Parameter(Mandatory = $true)][string]$Gcc,
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $tempBinary = Join-Path $env:TEMP ("aicee_" + [guid]::NewGuid().ToString("N") + ".exe")
    $diagFile = Join-Path $env:TEMP ("aicee_" + [guid]::NewGuid().ToString("N") + ".txt")
    $batchFile = Join-Path $env:TEMP ("aicee_" + [guid]::NewGuid().ToString("N") + ".bat")
    $gccBinDir = Split-Path -Parent $Gcc

    # Written to a real .bat file and executed directly instead of passing a
    # quoted command string through cmd /c: once any path here (gcc, source,
    # temp files) contains a space, nesting that many quoted arguments inside
    # one command-line string makes cmd.exe's own quote-stripping rules mangle
    # it. A batch file with plain, literal quoting has no such ambiguity, and
    # running .bat file as a native call also keeps stderr out of PowerShell's
    # own ErrorRecord conversion.
    #
    # gcc invokes its assembler ("as") and linker helper by bare name, not by
    # absolute path, so it relies on PATH to find them. Prepending the
    # compiler's own bin folder here (scoped to just this one batch process)
    # guarantees that resolves correctly even when the bundled compiler is
    # the only one on the machine and nothing else has put it on PATH.
    @"
@echo off
set PATH=$gccBinDir;%PATH%
"$Gcc" -std=c11 -Wall -Wextra -Wpedantic -fdiagnostics-color=never "$SourcePath" -o "$tempBinary" 2> "$diagFile"
"@ | Set-Content -Path $batchFile -Encoding ASCII

    & $batchFile
    $exitCode = $LASTEXITCODE
    Remove-Item -Path $batchFile -Force -ErrorAction SilentlyContinue

    $diagnostics = ""
    if (Test-Path $diagFile) {
        $diagnostics = (Get-Content -Path $diagFile -Raw -ErrorAction SilentlyContinue)
        Remove-Item -Path $diagFile -Force -ErrorAction SilentlyContinue
    }
    if ($null -eq $diagnostics) {
        $diagnostics = ""
    }

    if (Test-Path $tempBinary) {
        Remove-Item -Path $tempBinary -Force -ErrorAction SilentlyContinue
    }

    return [pscustomobject]@{
        Success     = ($exitCode -eq 0)
        Diagnostics = $diagnostics
    }
}

function Show-SmartExplanation {
    param([string]$Diagnostics)

    if ([string]::IsNullOrWhiteSpace($Diagnostics)) {
        return
    }

    $pattern = '^(?<location>.+?):\s*(?<kind>error|warning):\s*(?<message>.*)$'
    $entries = @()

    foreach ($line in ($Diagnostics -split "`r?`n")) {
        if ($line -match $pattern) {
            $entries += [pscustomobject]@{
                Location = $Matches.location
                Kind     = $Matches.kind
                Message  = $Matches.message
            }
        }
    }

    if ($entries.Count -eq 0) {
        return
    }

    Write-Host ""
    Write-Host "=== Smart Explanation ===" -ForegroundColor Cyan

    $index = 0
    foreach ($entry in $entries) {
        $index++
        $msg = $entry.Message
        $cause = ""
        $fix = ""

        if ($msg -match "expected ',' or ';'" -or $msg -match "expected ';'") {
            $cause = "A statement or declaration just above this line is missing a semicolon (;)."
            $fix = "Add the missing semicolon at the end of the previous line, then recompile."
        } elseif ($msg -match "undeclared") {
            $cause = "This name is used before it was declared, or an earlier missing semicolon broke the statement so the declaration never took effect."
            $fix = "Declare the variable or function before using it, check the spelling, and fix any error reported above this one first."
        } elseif ($msg -match "expected '\)'") {
            $cause = "A closing parenthesis is missing, or an earlier token inside the parentheses is invalid."
            $fix = "Check that every '(' in this statement has a matching ')' and that the expression inside is complete."
        } elseif ($msg -match "expected '\}'" -or $msg -match "expected declaration or statement at end of input") {
            $cause = "A closing brace '}' is missing, so the compiler reached the end of the file while still inside a block."
            $fix = "Check that every '{' has a matching '}', especially around the function or block mentioned above."
        } elseif ($msg -match "expected statement") {
            $cause = "This is a knock-on effect of the error reported just above it; the parser could not recover cleanly."
            $fix = "Fix the error above first, then recompile. This one will likely disappear on its own."
        } elseif ($msg -match "too few arguments") {
            $cause = "This function is being called with fewer arguments than its declaration requires."
            $fix = "Check the function's prototype and pass every required argument."
        } elseif ($msg -match "too many arguments") {
            $cause = "This function is being called with more arguments than its declaration accepts."
            $fix = "Remove the extra argument(s), or update the function's prototype."
        } elseif ($msg -match "implicit declaration") {
            $cause = "This function is called before it has been declared, or its header was not included."
            $fix = "Add a prototype above main(), or #include the header that declares it."
        } elseif ($msg -match "conflicting types") {
            $cause = "This function or variable is declared more than once with different types or signatures."
            $fix = "Make sure every declaration of this name uses the same return type and parameter list."
        } elseif ($msg -match "incompatible pointer" -or $msg -match "incompatible type") {
            $cause = "A value of one type is being assigned to, or compared with, an incompatible type."
            $fix = "Check the types on both sides and add an explicit cast only if the conversion is intentional."
        } elseif ($msg -match "unused variable" -or $msg -match "unused parameter") {
            $cause = "This variable or parameter is declared but never used anywhere in the function."
            $fix = "Remove it if it is not needed, or use it if it was meant to be used."
        } elseif ($msg -match "control reaches end of non-void function") {
            $cause = "This function is declared to return a value, but at least one code path falls off the end without a return statement."
            $fix = "Add a return statement that covers every possible path through the function."
        } elseif ($msg -match "redefinition") {
            $cause = "This name is defined more than once in a way the compiler cannot merge."
            $fix = "Keep only one definition, or move the extra one into a header guarded with #ifndef/#define."
        } else {
            $cause = "GCC reported this exact issue below; no specific pattern is matched for it."
            $fix = "Read the message together with the quoted source line and the caret (^) position above."
        }

        $kindLabel = if ($entry.Kind -eq "warning") { "Warning" } else { "Error" }

        Write-Host ""
        Write-Host "[$index] ${kindLabel}: $msg"
        Write-Host "    Location     : $($entry.Location)"
        Write-Host "    Likely Cause : $cause"
        Write-Host "    Suggested Fix: $fix"
    }
}

function Invoke-Analysis {
    param(
        [Parameter(Mandatory = $true)][string]$Gcc,
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    if (-not (Test-Path $SourcePath)) {
        Write-Host "Error: Unable to read the source file: $SourcePath" -ForegroundColor Red
        return 1
    }

    Write-Host ""
    Write-Host "Compiling: $SourcePath" -ForegroundColor Cyan

    $result = Invoke-CCompilation -Gcc $Gcc -SourcePath $SourcePath

    if ($result.Success) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Compilation Successful" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green

        if (-not [string]::IsNullOrWhiteSpace($result.Diagnostics)) {
            Write-Host ""
            Write-Host "The program compiled, but GCC reported warnings."
            Write-Host ""
            Write-Host "=== Raw GCC Warning Output ===" -ForegroundColor Yellow
            Write-Host $result.Diagnostics
            Show-SmartExplanation -Diagnostics $result.Diagnostics
        } else {
            Write-Host "No compiler errors or warnings were detected."
        }

        return 0
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Compilation Failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "=== Raw GCC Diagnostic Output ===" -ForegroundColor Yellow
    Write-Host $result.Diagnostics

    Show-SmartExplanation -Diagnostics $result.Diagnostics

    return 2
}
