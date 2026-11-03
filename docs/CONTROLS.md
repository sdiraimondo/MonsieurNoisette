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

Verified on the headless route:

- Start enters the game from the title screen.
- Right moves the player.
- The first level loads and renders.

Still to verify with a real display and controller:

- jump and run/attack buttons;
- pause;
- shoulder buttons if the game uses them;
- gamepad hot-plug and multiple controllers.
