# NES for Sonix Plus

Nintendo Entertainment System games on the HiBy R1 and R3 Pro II, as an
[app](https://github.com/Simplyph0/sonix-plus/blob/main/APPS.md) for
[Sonix Plus](https://github.com/Simplyph0/sonix-plus): the
[FCEUmm](https://github.com/libretro/libretro-fceumm) libretro core linked into the
[SDK](https://github.com/Simplyph0/sonix-app-sdk)'s frontend as one static program.

The game fills the top of the screen and an on-screen pad is below it: a D-pad, A and B,
SELECT and START, and SAVE, LOAD, MENU and EXIT keys. SAVE and LOAD keep one save state per game.
MENU opens the options (FPS counter, sound on or off, frame skip) and pauses the game. EXIT takes two taps
(the first turns it into SURE?), so a thumb passing over it cannot end the game. Battery saves are written to `Saves/NES/<game>.srm` on the card,
and again within twenty seconds of any change.

## Installing

1. Copy the `NES` folder to `Apps/` on the card (a release has it ready, or build it as below).
2. Put games (`.nes`, `.fds`, `.unf`) in `Games/NES/` on the card. The app lists what is there.
3. Open **More > Emulators > NES**.

Core options can be changed in a `core.opt` file in the app's folder, one `key = value` per
line, using the option names of FCEUmm (for example `fceumm_palette = default`).

## Building

You need the MIPS toolchain that `make target` builds in the Sonix Plus repository
(`sonix-player/rockbox-toolchain`), and `git`.

```bash
make fetch                                  # the SDK and the core, into ./sdk and ./core
make package CROSS=/path/to/sonix-plus/sonix-player/rockbox-toolchain/bin/mipsel-rockbox-linux-gnu-
```

`dist/NES/` is the folder to copy to the card. `make host` builds a program for your
computer instead, and `python3 tools/mkrom.py test.nes` writes a small ROM of my own to try it
with: `SONIX_FB=frame.raw SONIX_TEST_FRAMES=60 build-host/nes test.nes` runs it for a second
and writes the last picture, as raw RGB565, to `frame.raw`.

## Licences

The files in this repository (the Makefile, manifest, icon and the test ROM generator) are MIT.
FCEUmm is under the GNU GPL version 2 or later, and so is the program built from it, which
includes the SDK's MIT-licensed frontend. The core's source is at the revision named in the
Makefile, and `make fetch` gets it.
