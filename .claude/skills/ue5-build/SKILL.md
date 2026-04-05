---
name: ue5-build
description: >
  Skill for building UE5 (Unreal Engine 5) from source on Windows.
  Use this skill whenever the user says things like "I want to build UE5", "compile Unreal Editor",
  "run a DebugGame build", "getting a UBT error", "run GenerateProjectFiles", or "check if build
  processes are conflicting" — or when they paste an error message related to UnrealBuildTool /
  Build.bat / UE5 builds. Assumes a Perforce environment; GitHub checkout steps are not included.
---

# UE5 Source Build Assistant Skill

This skill guides users through building UE5 from source on Windows.
**Default target**: `UnrealEditor` / `Win64` / `DebugGame`

---

## Step 1: Confirm the UE5 Root Directory

First, ask the user for the root path of their UE5 source (e.g., if `D:\UE5\Engine` exists, then `D:\UE5` is the root).

Verify that the following exist under the root:
- `Engine\Build\BatchFiles\Build.bat`
- `Engine\Source\`
- `UE5.sln` or project files corresponding to a `.uproject`

---

## Step 2: Exclusive Build Check (Important)

UE5 builds are **exclusive** — running multiple build processes simultaneously will cause failures or corruption. Before building, instruct the user to confirm that none of the following processes are running:

```powershell
# Commands to check for conflicting processes
tasklist /FI "IMAGENAME eq MSBuild.exe"
tasklist /FI "IMAGENAME eq UnrealBuildTool.exe"
tasklist /FI "IMAGENAME eq cl.exe"
tasklist /FI "IMAGENAME eq xgConsole.exe"
tasklist /FI "IMAGENAME eq xge.exe"
```

If conflicting processes are found:
- Stop any active Visual Studio build
- Check whether other Claude sessions or CI builds are running
- If Incredibuild is active, wait for jobs to finish or stop them

If no processes are found, proceed to the next step.

---

## Step 3: Run the Build Command

### Standard Build (Recommended)

Run the following from the UE5 root:

```batch
Engine\Build\BatchFiles\Build.bat UnrealEditor Win64 DebugGame -WaitMutex
```

**Argument meanings**:
- `UnrealEditor` — Build target (the editor itself)
- `Win64` — Platform
- `DebugGame` — Configuration (engine is release-optimized; game code is debug)
- `-WaitMutex` — Wait for other UBT processes to finish before starting (helps with exclusive access)

### Option: Clean Build

If the issue appears to be caused by stale cache or intermediate files, run Clean first:

```batch
Engine\Build\BatchFiles\Clean.bat UnrealEditor Win64 DebugGame
Engine\Build\BatchFiles\Build.bat UnrealEditor Win64 DebugGame -WaitMutex
```

### Option: GenerateProjectFiles

If the `.sln` is broken or this is initial setup:

```batch
Engine\Build\BatchFiles\GenerateProjectFiles.bat
```

---

## Step 4: Verify Build Output

**On success**: The log will end with `BUILD SUCCESSFUL` or `Build successful.`

Generated binaries:
```
Engine\Binaries\Win64\UnrealEditor.exe                      (executable)
Engine\Binaries\Win64\UnrealEditor-Win64-DebugGame.dll      (game code DLL)
```

---

## Common Errors and Fixes

### `ERROR: Couldn't find target rules file`
- The UE5 root path is likely wrong
- Confirm that `Build.bat` is being run from the UE5 root
- If building a project-specific target, specify the path to the `.uproject`

### `error C1083: Cannot open include file` / Header not found
- Possible corruption in the Intermediate folder cache
- Delete `Engine\Intermediate\` and `Engine\Saved\`, then rebuild
- Re-run `GenerateProjectFiles.bat` before rebuilding

### Link errors (`LNK2001`, `LNK1120`)
- Delete the Binaries folder, run Clean, then rebuild
- Often caused by PCH (precompiled header) inconsistency

### `MSVC version` / `Windows SDK version` errors
- Verify that the C++ desktop development workload is installed in Visual Studio
- Check the required MSVC version in `Engine\Build\BuildConfiguration.xml` or the official docs
- If multiple VS versions are installed, ensure the version expected by UE5 takes priority

### `The process cannot access the file because it is being used by another process`
- Return to Step 2's exclusive build check
- Antivirus may be locking `Engine\Intermediate\` — check exclusion settings

### Long `-WaitMutex` wait / timeout
- Remove `-WaitMutex` to force execution, or manually kill the `UnrealBuildTool.exe` process and retry

---

## Related Skills

- **ue5-game-build** (planned): Assistance for Game target and Shipping build checks
