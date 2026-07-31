# C Compiler Error Explainer

A VS Code-ready C project that compiles a `.c` file with GCC, captures compiler diagnostics, and explains the first likely root cause in clear professional English.

## Features

- Compiles C11 source files with GCC.
- Captures and shows the raw errors and warnings from GCC.
- Includes VS Code build, run, test, and debug tasks.
- Works with paths containing spaces.
- Uses English-only console output and source comments.
- Ships with its own compiler in `tools/mingw/` — nothing to install. Download this repository as a zip, unzip it, and run `START_HERE.bat`.

## Fastest Way to Run on Windows

No install step: download this repository (as a zip, or `git clone`), open the folder in VS Code, then run:

```powershell
.\START_HERE.bat
```

The file `playground/user_code.c` intentionally contains a missing semicolon so that the explainer shows a real result.

After editing `playground/user_code.c`, press:

```text
Ctrl+Shift+B
```

## Analyze the Current C File

Open any `.c` file in VS Code, then use:

```text
Terminal > Run Task > 4. Analyze Current C File
```

## Commands

Check GCC and GDB:

```powershell
.\CHECK_SETUP.bat
```

Build and analyze the playground file:

```powershell
.\BUILD_AND_RUN.bat
```

Build only the offline executable:

```powershell
.\build_offline_windows.bat
```

Run all project tests from VS Code:

```text
Terminal > Run Task > 5. Run Project Tests
```

## Project Structure

```text
src/          C source and header files
scripts/      PowerShell build and run scripts
playground/   File used for normal testing
examples/     Sample correct and incorrect C programs
tools/mingw/  Bundled compiler (used automatically; no install needed)
.vscode/      VS Code tasks, settings, and debugger configuration
bin/          Generated Windows executables
```

## Output Format

```text
Compilation Failed

=== Raw GCC Diagnostic Output ===
...
```

## Exit Codes

- `0`: The target C file compiled successfully.
- `1`: The explainer encountered a setup, input, or internal error.
- `2`: The target C file contains a compiler error. This is an expected analysis result.
