# aseprite-script-color-cell-compression
Color cell compression script for Aseprite

![example of what this extension renders as](./example.png)

This is an implementation of the "cell" part of colour cell compression
https://en.wikipedia.org/wiki/Color_Cell_Compression

This basically renders every 4x4 cell as a 1-bit bitmap, each with it's own 2-colour palette.
This quantisation part of the algorithm is left alone, aseprite itself does that far better than what i'd manage on my own.

Despite the primitive technique and simple rendering the results can look surprisingly decent.

Install:
1) Open Aseprite
2) Go to File > Scripts > Open scripts folder
3) Copy this file to the scripts folder
4) In Aseprite, go to File > Scripts > Rescan scripts folder
5) Run the script: File > Scripts > palettize

Usage:
1) File > Scripts > palettize

Made by MiiFox
