# bigstack

A tiny `DYLD_INSERT_LIBRARIES` shim that forces every pthread to get a big stack,
plus a Steam launch wrapper for Stellaris on macOS.

## Why

On the native Mac port of Stellaris 4.5.1, starting a new game with
Star Trek: New Horizons (or presumably any mod with a large static galaxy)
crashes during galaxy generation:

```
InitializeEmpireSystemsForStaticGalaxy(CCrudeRandom&, SGalaxyGenerationMetaData&, SGalaxyPartitionsData&)
CGalaxyGenerator::GenerateFromStaticScenario(CGalaxyConfiguration const&, CCrudeRandom&)
CGalaxyGenerator::Generate(CGalaxyConfiguration const&, int)
CGameState::GenerateNewGalaxy(int)
CFrontEndIdler::LaunchNewGame()
CPdxTaskScheduler::RunTasks(...)
```

That function does an `alloca(n * 416)` sized by the empire count, and the
fault is inside the `___chkstk_darwin` stack probe. It runs on a task-scheduler
worker thread with the 512 KiB macOS default stack. The same mod is fine on
Windows, where thread stacks default to 1 MiB.

`libbigstack.dylib` interposes `pthread_create` and `pthread_attr_setstacksize`
so no thread gets less than `BIGSTACK_MB` (default 64) MiB. That's just reserved
address space; pages are only committed as they're touched.

## Use

```sh
G="$HOME/Library/Application Support/Steam/steamapps/common/Stellaris"
mkdir -p "$G/bigstack"
clang -arch arm64 -arch x86_64 -dynamiclib -O2 -o "$G/bigstack/libbigstack.dylib" bigstack.c
cp run-stellaris.sh "$G/bigstack/" && chmod +x "$G/bigstack/run-stellaris.sh"
```

Then set Stellaris's Steam Launch Options to:

```
"/Users/YOU/Library/Application Support/Steam/steamapps/common/Stellaris/bigstack/run-stellaris.sh" %command%
```

Notes:

- The wrapper starts the game directly, skipping the Paradox Launcher. Mods come
  from `~/Documents/Paradox Interactive/Stellaris/dlc_load.json`, so set up your
  playset in the launcher first (clear the launch option, pick mods, put it back).
- Steam's Mac client runs under Rosetta, so its children default to the x86_64
  slice. The wrapper uses `arch -arm64` to get the native build.
- Each thread whose stack gets bumped is logged to `~/Library/Logs/stellaris-bigstack.log`.
- This only works because the Stellaris binary is ad-hoc signed without the
  hardened runtime; dyld ignores `DYLD_INSERT_LIBRARIES` for hardened binaries.
