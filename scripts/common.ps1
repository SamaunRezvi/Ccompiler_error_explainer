$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BundledGcc = Join-Path $ProjectRoot "tools\mingw\bin\gcc.exe"
$BundledGdb = Join-Path $ProjectRoot "tools\mingw\bin\gdb.exe"

function Find-Tool {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$FallbackPaths
    )

    foreach ($path in $FallbackPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    return $null
}

function Find-Gcc {
    return (Find-Tool -Name "gcc" -FallbackPaths @(
        $BundledGcc,
        "C:\msys64\ucrt64\bin\gcc.exe",
        "C:\msys64\mingw64\bin\gcc.exe",
        "C:\MinGW\bin\gcc.exe"
    ))
}

function Find-Gdb {
    return (Find-Tool -Name "gdb" -FallbackPaths @(
        $BundledGdb,
        "C:\msys64\ucrt64\bin\gdb.exe",
        "C:\msys64\mingw64\bin\gdb.exe",
        "C:\MinGW\bin\gdb.exe"
    ))
}
