# Obsi Game Engine (1.5.0)

Changes from the previous release:
* Added new object with filesystem: `obsi.File`
* Added new module for working with game's directory: `obsi.filesystem` (very similar to Love2D's except for some missing features.)
* Added new functions for the module: `obsi.filesystem.newFile`, `obsi.filesystem.getInfo`, `obsi.filesystem.read`, `obsi.filesystem.write`, `obsi.filesystem.lines`
* Modules like `obsi.audio` and `obsi.graphics` now depend on `obsi.filesystem`
* New version of rendering API `pixelbox` is now used, which is 5-7x better than the older version. Allows native performance for better resolution.
* Some error messages were changed for better debugging of the engine.

## Obsi Game Engine (1.5.1)

Changes from the previous release:
* Added new important functions for the filesystem module: `obsi.filesystem.createDirectory`, `obsi.filesystem.getDirectoryItems`, `obsi.filesystem.remove`.
* Added annotations for each module of Obsi to improve experience with VSCode.
* Errors on failing to execute `config.lua` and `main.lua` files are handled.