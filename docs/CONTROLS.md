# Controls

The current port uses the framework's standard SNES controller mapping. The
old port's custom `SwapInputBits` layout and its `B = right`, `Y = left`
workarounds were removed; they no longer describe the framework.

## Keyboard defaults

The framework reads `keybinds.ini` beside the executable. Defaults:

| SNES | Key |
|---|---|
| D-pad | Arrow keys |
| A | X |
| B | Z |
| X | S |
| Y | A |
| L | C |
| R | V |
| Start | Return |
| Select | Right Shift |

## Gamepad defaults

SDL-compatible controllers are auto-detected. The default Xbox-layout mapping
is:

| SNES | Gamepad |
|---|---|
| D-pad | D-pad |
| A | B (south) |
| B | A (east) |
| X | Y (west) |
| Y | X (north) |
| L | LB |
| R | RB |
| Start | Start |
| Select | Back |

Both keyboard and gamepad are active at the same time. Edit `config.ini` and
`keybinds.ini` beside the executable to rebind; they are generated at runtime
and are not tracked by Git.

## Validation status

Verified with a display (Xvfb) and the framework's virtual gamepad:

- Start enters the game from the title screen.
- Right moves the player; X (SNES A) jumps and collects coins.
- Shift+P pauses the guest.
- The save-state browser and the rewind filmstrip open and close from the pad
  gestures (Select+R / Select+R3).
- Alt+Return toggles the persisted fullscreen flag.

Still to verify with a physical controller:

- real button presses (jump, run/attack, pause);
- shoulder buttons if the game uses them;
- gamepad hot-plug and multiple controllers.

Keyboard and gamepad use the framework's standard mapping; the validated
keyboard route does not replace a physical pad check.
