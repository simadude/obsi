# Obsi 2D Game Engine (CC:Tweaked)

![Obsi logo](obsi-logo.png)

Obsi is a game engine that was designed specifically for CC:Tweaked.

Features of the game engine:
* It's 2D (I literally didn't implement triangles. DON'T EVEN TRY TO MAKE IT 3D.)
* It's lightweight - The raw source code is only around 50KB.
* Very similar to Love2D - if you are familiar with that engine, Obsi will be very easy to grasp!
* Customizable color palette - if you think the colors that CC provides you with are very limited, why not change them?
* Better image format - Obsi supports another image format besides `.nfp` called `.orli` (pronounced as Orley, stands for "Obsi Run-Length Image"). This format can be up to 6-10x smaller than `.nfp`.
* 3 Different renderering APIs! Including: `Pixelbox` (by Dev9551), `Parea`, `Hmon`.
* Resizability - you can change the resolution ingame and the engine will still perform fine! (if it doesn't then it's your fault, probably)
* Tilesheets - if your image is a map of images with the same width and height, Obsi can directly give you an array of images using `obsi.graphics.newImagesFromTilesheet`.


Features that are not implemented:
* Networking (No plans for that yet.)
* Support for `.png` (Yeah, Dev9551, I've seen your png parser, but Holy Christ, it's too large!)
* Changing rendering APIs on runtime (Currently can only be changed in the `config.lua` file of the game.)
* Triangles (Did I mention that this is a 2D game engine?)
* Bundler/minifier - There are plans for Obsi to have a bundler in the repository, so that when you download it, you can bundle everything up and reduce its size significantly.
* Installer - If I will ever make an installer for this thing, it will probably will have a bit of telemetry to see what version of CC:Tweaked you are using, and whether you are on emulator or not.