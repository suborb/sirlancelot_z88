# Sir Lancelot (z88 version)

This project contains the source code for the z88 port of the
ZX Spectrum game Sir Lancelot.

## Compilation

To compile you'll need a modern version of z88dk setup and
available in the path. The application can then be generated
by invoking `make`.

## Background

The source code is pretty much as it was when released in 1998, so 
contains (amongst other things):

- Wonky whitespace
- Commented out code
- Cryptic labels
- Development comments/queries from the disassembly
- False comments

The following changes have been made:

- Update to assemble with the version of z80asm within z88dk
- Updates to remove old email addresses

As a result, the version has been bumped.

## In-game Controls

The preset keys are:

Left    - O
Right   - P
Jump    - Space
Pause   - H

These movement keys can be redefined to suit your playing style/hand size!

There is also a set of control keys which cannot be redefined:

ESC     - Quit back to intro from game
TAB     - Toggle screen size - mini/standard
DEL     - Toggle inverse background

Sir Lancelot is quite a noisy game, with music and sound effects, these
may be toggled on or off by using the Sound setting from the panel - this
can be set at anytime and it will be immediately obeyed.

## Acknowledgements

Sir Lancelot was original written by Stephen Cargill and published by
Melbourne House.
