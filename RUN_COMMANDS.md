# Run Commands

## Recommended

From the project root in the VS Code PowerShell terminal:

```powershell
.\START_HERE.bat
```

## Without the Batch File

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_here.ps1
```

## Analyze the Playground File Again

```powershell
.\BUILD_AND_RUN.bat
```

## Check GCC and GDB

```powershell
.\CHECK_SETUP.bat
```

## Build the Offline Executable Only

```powershell
.\build_offline_windows.bat
```

## Run the Offline Executable Directly

```powershell
.\bin\error-explainer.exe .\playground\user_code.c --offline
```

## VS Code Keyboard Command

Press `Ctrl+Shift+B` to build the explainer and analyze `playground/user_code.c`.
