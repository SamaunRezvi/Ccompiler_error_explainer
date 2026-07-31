<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=26&pause=1000&color=00FF41&background=0D1117&center=true&vCenter=true&width=800&height=60&lines=%24+START_HERE.bat" alt="terminal prompt" />
</p>

<p align="center">
  <a href="#quick-start">
    <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=500&size=17&duration=1800&pause=700&color=00FF41&background=0D1117&center=true&vCenter=true&repeat=true&width=800&height=170&lines=%24+gcc+user_code.c;compiling...;error%3A+expected+%27%2C%27+or+%27%3B%27+before+%27printf%27;+++%5E~~~~~~;%3E+explained%3A+missing+semicolon+on+the+previous+line.;%3E+fix+applied.+recompiling...;compilation+successful." alt="terminal boot animation" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-C11-6fa8ff?style=for-the-badge&logo=c&logoColor=white" alt="Language: C11" />
  <img src="https://img.shields.io/badge/Platform-Windows-8fd693?style=for-the-badge&logo=windows&logoColor=white" alt="Platform: Windows" />
  <img src="https://img.shields.io/badge/Compiler-Bundled-ffb454?style=for-the-badge&logo=gnu&logoColor=white" alt="Compiler bundled" />
  <img src="https://img.shields.io/badge/Setup-Zero%20Install-ff6b6b?style=for-the-badge&logo=windowsterminal&logoColor=white" alt="Zero install" />
  <img src="https://img.shields.io/badge/Network-Not%20Required-1b1e29?style=for-the-badge&logo=off&logoColor=white" alt="Fully offline" />
  <img src="https://img.shields.io/badge/License-MIT-00FF41?style=for-the-badge&logo=github&logoColor=white" alt="License: MIT" />
</p>

<p align="center">
  <sub>Download the repo, run one script, and get a plain-English breakdown of every compiler error, no setup required.</sub>
</p>

---

## Overview

GCC is precise but unfriendly. A single missing semicolon can produce a wall of cryptic
follow-on errors that bury the real problem. **C Compiler Error Explainer** compiles your
`.c` file, captures every diagnostic exactly as GCC printed it, then walks through each one
and explains, in plain language, what broke, why it broke, and how to fix it.

It ships with its own compiler (`tools/mingw/`), so there is nothing to install: download
this repository, run one script, and it works.

## Why This Exists

A beginner staring at this:

```text
error: expected ',' or ';' before 'printf'
```

usually has no idea the real problem is on the *previous* line. This tool exists to close
that gap, turning raw compiler noise into a short, specific explanation for every single
error and warning GCC reports, no matter how many there are.

## Features

| | |
|---|---|
| 🧠 **Explains every error** | Not just the first one. Hundreds of errors in one file get the same full treatment. |
| 📦 **Zero install** | A trimmed, portable GCC ships inside the repo. No MSYS2, no PATH setup, no admin rights. |
| 🔍 **Real diagnostics, not guesses** | Every explanation is derived from GCC's own output, not a canned response. |
| 🖥️ **Works from VS Code or the terminal** | Built-in tasks for build, analyze, test, and debug. |
| 📏 **No arbitrary limits** | File size, error count, and line length are unbounded, tested against a 300-error file. |
| 🪟 **Handles messy Windows paths** | Works correctly even when the project lives under a folder name with spaces. |

## How It Works

```mermaid
flowchart LR
    A["Your .c file"] --> B["Bundled GCC compiles it"]
    B --> C["Every error / warning line is parsed out"]
    C --> D["Each one is matched to a cause + fix"]
    D --> E["Plain-English explanation, per line"]

    style A fill:#1b1e29,stroke:#2e3346,color:#e7e9f2
    style B fill:#1b1e29,stroke:#6fa8ff,color:#e7e9f2
    style C fill:#1b1e29,stroke:#ffb454,color:#e7e9f2
    style D fill:#1b1e29,stroke:#ff6b6b,color:#e7e9f2
    style E fill:#1b1e29,stroke:#63d9c7,color:#e7e9f2
```

## Quick Start

> **No install step.** Download this repository (as a zip, or `git clone`), unzip it if
> needed, then run one script. The bundled compiler in `tools/mingw/` is used automatically.

```powershell
.\START_HERE.bat
```

`playground/user_code.c` intentionally contains a bug so the first run shows a real result.
Edit it and press `Ctrl+Shift+B` in VS Code to analyze it again.

## Example

Real output, captured from this tool analyzing `examples/missing_semicolon.c`:

```text
Compiling: examples/missing_semicolon.c

========================================
Compilation Failed
========================================

=== Raw GCC Diagnostic Output ===
examples/missing_semicolon.c: In function 'main':
examples/missing_semicolon.c:5:5: error: expected ',' or ';' before 'printf'
     printf("Age: %d\n", age);
     ^~~~~~
examples/missing_semicolon.c:4:9: warning: unused variable 'age' [-Wunused-variable]
     int age = 20
         ^~~

=== Smart Explanation ===

[1] Error: expected ',' or ';' before 'printf'
    Location     : examples/missing_semicolon.c:5:5
    Likely Cause : A statement or declaration just above this line is missing a semicolon (;).
    Suggested Fix: Add the missing semicolon at the end of the previous line, then recompile.

[2] Warning: unused variable 'age' [-Wunused-variable]
    Location     : examples/missing_semicolon.c:4:9
    Likely Cause : This variable or parameter is declared but never used anywhere in the function.
    Suggested Fix: Remove it if it is not needed, or use it if it was meant to be used.
```

## Commands

| Script | What it does |
|---|---|
| `START_HERE.bat` | Builds nothing extra, analyzes `playground/user_code.c` immediately |
| `CHECK_SETUP.bat` | Verifies the compiler and debugger are reachable |
| `BUILD_AND_RUN.bat` | Re-analyzes the playground file |
| `build_offline_windows.bat` | Builds the standalone `error-explainer.exe` |

Or from VS Code: `Terminal > Run Task`, then pick **Analyze Current C File** or **Run Project
Tests**.

## Project Structure

```text
src/          C source and header files
scripts/      PowerShell build and run scripts
playground/   File used for day-to-day testing
examples/     Sample correct and incorrect C programs
tools/mingw/  Bundled compiler, used automatically, nothing to install
.vscode/      VS Code tasks, settings, and debugger configuration
bin/          Generated Windows executable
```

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | The target file compiled successfully |
| `1` | Setup, input, or internal error (not a code problem) |
| `2` | The target file contains a compiler error (expected analysis result) |

## License

Licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute this
project, including commercially, as long as the original copyright notice below is kept
intact in any copy or substantial portion of the code.

---

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=500&size=15&pause=2000&color=2E3346&background=0D1117&center=true&vCenter=true&width=700&height=40&lines=%C2%A9+2026+Samaun+Rezvi.+Licensed+under+the+MIT+License." alt="copyright" />
</p>
