function Find-Tool {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$FallbackPaths
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    foreach ($path in $FallbackPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Find-Gcc {
    return (Find-Tool -Name "gcc" -FallbackPaths @(
        "C:\msys64\ucrt64\bin\gcc.exe",
        "C:\msys64\mingw64\bin\gcc.exe",
        "C:\MinGW\bin\gcc.exe"
    ))
}

function Find-Gdb {
    return (Find-Tool -Name "gdb" -FallbackPaths @(
        "C:\msys64\ucrt64\bin\gdb.exe",
        "C:\msys64\mingw64\bin\gdb.exe",
        "C:\MinGW\bin\gdb.exe"
    ))
}
