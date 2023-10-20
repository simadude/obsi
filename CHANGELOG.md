# Obsi Game Engine (1.2.0)

Changes from the previous release:
* Added volume settings for specific sound/id `obsi.audio.setVolume` and `obsi.audio.getVolume`.
* Added `obsi.audio.playSound` (only works in minecraft, does nothing on CraftOS-PC)
* Added `obsi.graphics.clearPalette` for clearing the palette to a default one.
* Added functions got setting the specific rendering API at runtime using `obsi.graphics.setRenderer` and `obsi.graphics.getRenderer`.
* Better parity between with 3 different rendering APIs.
* Fixed `obsi.system.isEmulated` now works properly.