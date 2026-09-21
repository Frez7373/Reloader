# Reloader

Factory reset utility for CC:Tweaked.

## Install

```lua
wget https://raw.githubusercontent.com/Frez7373/Reloader/main/reloader.lua reloader
```

Then run:

```lua
reloader
```

The program asks for `RESET` before deleting anything.

### Reset behavior

- Deletes all writable files and directories from the computer root.
- Removes startup files and saved user settings because they are ordinary user files.
- Resets the computer label.
- Preserves `rom`.
- Preserves the mounted `disk`/floppy media.
- Reboots the computer after the reset.
