# Space Haven Live Trainer

External Windows trainer and runtime mod for **Space Haven**.

**Author:** Luca Cococcioni  
**Current version:** v0.7.2  
**Tested game build:** `1.0.4_steam`  
**Minimum Mod Loader version:** `0.10.0`

> This is an unofficial community project and is not affiliated with, endorsed by, or supported by Bugbyte Ltd.

## What it is

Space Haven Live Trainer is made of two components:

```text
External Windows GUI
        |
        |  localhost 127.0.0.1:17840
        v
SpaceHavenLiveTrainer mod
        |
        v
Space Haven runtime data
```

The GUI does not edit save files directly. It sends local commands to the mod loaded with Space Haven. The mod applies them from the game's update cycle.

## Main features

- Credits and live resource injection
- Infinite Resources with smooth replenishment
- Independent crew toggles:
  - health
  - oxygen
  - food
  - rest
  - mood
  - comfort
- Live crew editor
- Skill editing up to `10/10`
- Attribute editing up to the game's real limit `5/5`
- One-click **MAX PERSONAGGIO**
- Remove removable negative conditions
- Live research list
- Complete one technology
- Complete all visible technologies
- Instant Research toggle
- External GUI with live status and hotkey synchronization
- Local-only communication on `127.0.0.1:17840`

## Requirements

- Windows
- Space Haven
- Space Haven Mod Loader
- Windows PowerShell 5.1 or newer

`spacehaven.jar` is **not included** in this repository or in releases.

## Quick installation

1. Download the ZIP from GitHub Releases.
2. Extract it.
3. Run `INSTALLA_MOD.bat`.
4. The installer tries to detect Space Haven in your Steam libraries.
5. Open Space Haven Mod Loader.
6. Confirm that **Space Haven Live Trainer v0.7.2** is enabled.
7. Use **Clear QuickLaunch cache**.
8. Launch Space Haven through the Mod Loader and load a game.
9. Run `AVVIA_GUI.bat`.

If automatic detection fails, the installer asks you to select the Space Haven folder manually.

## Hotkeys

| Key | Function |
| --- | --- |
| F1 | +100,000 credits |
| F2 | +50 Hyperfuel |
| F3 | Infinite Resources |
| F4 | Infinite Health |
| F5 | Infinite Oxygen |
| F6 | Stable Food |
| F7 | Stable Rest |
| F8 | Stable Mood |
| F9 | Stable Comfort |
| F10 | Instant Research |

All F3-F10 states are synchronized with the external GUI.

## Safety / networking

The trainer server binds only to:

```text
127.0.0.1:17840
```

It is not intended to listen on your LAN or on the Internet.

## Building the mod

The repository includes `build/Build-Mod.ps1`.

You need:

- a JDK with `javac` and `jar`;
- your own locally installed `spacehaven.jar`.

Example:

```powershell
.\build\Build-Mod.ps1 -SpaceHavenJar "C:\Program Files (x86)\Steam\steamapps\common\SpaceHaven\spacehaven.jar"
```

The game JAR is used only as a compile-time dependency and is never copied into the output mod.

## Repository layout

```text
mod/        compiled runtime mod
gui/        external Windows GUI
src/        source code
installer/  automatic installer
build/      local build script
docs/       documentation
dist/       ready-to-upload GitHub Release ZIP
```

## License

The original code in this repository is released under the MIT License.  
Space Haven and its assets remain the property of their respective rights holders.
