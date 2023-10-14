# Obsi Game Engine (1.1.0)

Changes from the initial release:
* The `obsi.sound` module was renamed into `obsi.audio`, with all of the functions.
* Added support for music (currently .nbs and .onb are supported.)
* Added support for .nbs files (Big thanks to [Xella's NBS Tunes](https://github.com/Xella37/NBS-Tunes-CC) for the parsing function.)
* All of the whitespaces where changed from 4-space indentation to a single tab character for reducing the file size across the scripts.
* Fixed flickering when resizing while using Pixelbox as a rendering api.
* Added `pixelbox.RESIZE` to the source code (to fix the issue above).
* Added features in `obsi.audio` for playing, pausing, unpausing and stopping the music.
* Added `obsi.version` to keep track of what version of the engine the game itself is running on.
* Added `obsi.system` for checking the environment the game engine is running on.