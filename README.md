# large-file-map
Makes visual map of files which are too large to fit in memory (allowed me to analyse an image of broken SD card).

The map is constantly updated during scan.

Requirements:
- Torch 7 (https://github.com/torch/torch7);
- Torch Image (https://github.com/torch/image);
- LuaFileSystem for files larger than 2 Gb (https://github.com/keplerproject/luafilesystem).

--
**Usage:**

`th large_file_map.lua -sd "test.jpg" -image "out.png" -x 1024 -y 768` 

--

Example image of 64 Gb SD card (1 pixel is ~100 kbytes; the beginning contains files and the rest is probably empty):

![Example image of SD card.](https://github.com/VaKonS/large-file-map/raw/master/test.jpg)
