# Obsi Game Engine (1.4.0)

Changes from the previous release:
* Added new objects: `obsi.Canvas`, `obsi.Scene`.
* Added a new module `obsi.state` for managing the new scene objects as well as global game variables.
* New callback functions: `obsi.resize`, `obsi.windowFlush`, `obsi.onEvent`.
* Exposing the `window` object using `obsi.windowFlush`.
* Error handling on crashes.
* Removal of certain if-statements for (hopefully) improving performance.
* Improved performance for orli parser.