# 3mf_thumb
This is a small set of custom thumbnailer scripts (mostly for 3D printing formats) that I crafted based on various samples floating about on the Internet, and which work in GNOME 42+.

## Supported Formats

* `.3mf` (Cura, PrusaSlicer, SuperSlicer, etc.)
* `.gcode` with embedded thumbnails
* `.scad` (OpenSCAD, will blindly render the default object)
* `.stl` (Actually uses OpenSCAD to render as well)
* `.blend` (uses the built-in `blender-thumbnailer` that comes with Blender)

## Installation

* sudo make install

## Dependencies

* `3mf.thumbnailer` and `gcode.thumbnailer` require nothing but Python 3 installed, because they cheat and use the thumbnail the slicer inserts into the file.
* `stlscad.thumbnailer` requires `Xvfb`, `openscad` and `ImageMagick` installed to render and convert files.
* `blender.thumbnailer` requires Blender to be installed.
