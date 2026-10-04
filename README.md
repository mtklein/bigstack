# bigstack for Stellaris on Mac

A small fix for Stellaris crashing while creating a galaxy with Star Trek: New
Horizons. It gives the game more room for its calculations.

The download includes the finished fix. You do **not** need to install programming
tools or know what `clang` is. It supports Apple Silicon and Intel Macs running
macOS 11 or later. You still need Stellaris installed through Steam.

## Install the fix

1. **Choose your mods first.** Open Stellaris normally, select your playset in the
   Paradox Launcher, and quit the game and launcher. The fix uses that selection.
2. **[Download the latest release](https://github.com/mtklein/bigstack/releases/latest).**
   Under **Assets**, choose **bigstack-v0.1.0-macos.zip**. Double-click the ZIP in
   Downloads to open it. Open the folder it creates. Leave that folder open.
   You can ignore the downloads called “Source code.”
3. **Open Terminal.** Press **Command-Space**, type **Terminal**, and press Return.
   Terminal is an app already on your Mac.
4. **Run setup.** In Terminal, type `bash` followed by **one space**. Drag
   **INSTALL.command** from the downloaded folder into the Terminal window.
   Click the Terminal window and press **Return**. Setup copies the fix into
   Stellaris and copies your Steam setting for you.
   If it asks for the game folder, open Steam, right-click Stellaris, choose
   **Manage → Browse local files**, and select that folder in the setup window.
5. **Paste the setting into Steam.** Right-click Stellaris in your Steam Library,
   choose **Properties**, and find **Launch Options** under **General**. Clear
   anything already in that box, then press **Command-V** to paste. Close
   Properties and click **Play**.

The game now opens directly, without the Paradox Launcher. You can close Terminal
and delete the downloaded ZIP and folder after setup finishes.

## Change your mods later

Clear **Launch Options** in Steam, then click **Play** to open the Paradox Launcher.
Choose your new playset and quit. Run setup again and paste the setting back into
Steam. Download the ZIP again if you deleted it.

## Undo the fix

Clear **Launch Options** in Steam. The game will start normally again. You can also
remove the `bigstack` folder inside your Stellaris folder.

## If something goes wrong

- **Setup says it cannot find Stellaris:** choose the folder containing
  `stellaris.app`, opened by Steam's **Manage → Browse local files**.
- **The Paradox Launcher still opens:** the Steam setting is missing or incorrect.
  Run setup again and paste its copied setting into **Launch Options**.
- **Your mods are missing:** follow “Change your mods later” above.
- **The game still crashes:** this fix addresses one specific galaxy-generation
  crash; other crashes can have other causes. To report a problem, include your
  macOS version, Stellaris version, mod name, and the file
  `stellaris-bigstack.log` from your Library's Logs folder. In Finder, choose
  **Go → Go to Folder**, paste `~/Library/Logs`, and press Return.

## Technical details

This was developed for the native Mac port of Stellaris 4.5.1. During static
galaxy generation, `InitializeEmpireSystemsForStaticGalaxy` uses an
`alloca(n * 416)` sized by empire count. On a task-scheduler worker with the
512 KiB macOS default stack, this can fail inside `___chkstk_darwin`.

`libbigstack.dylib` interposes `pthread_create` and `pthread_attr_setstacksize`
so threads get at least `BIGSTACK_MB` MiB (default 64). Caller-provided stacks
are left alone. This reserves address space; pages are committed as touched.

The wrapper finds Stellaris relative to its installed location, loads the library
with `DYLD_INSERT_LIBRARIES`, and logs to
`~/Library/Logs/stellaris-bigstack.log`. On Apple Silicon it selects the arm64
build, even when Steam runs under Rosetta. Intel Macs use the x86_64 build.
Mods come from `~/Documents/Paradox Interactive/Stellaris/dlc_load.json`.

This depends on the Stellaris executable allowing library injection. The original
executable was ad-hoc signed without the hardened runtime. A future game update
that changes this may prevent the fix from loading.

## Build a release (maintainers only)

On a Mac with Xcode Command Line Tools installed:

```sh
sh build-release.sh v0.1.0
```

This builds an ad-hoc signed universal library and creates the ZIP and its SHA-256
checksum in `dist/`. The downloadable build requires macOS 11 or later.
