# large-file-map
Makes visual map of files which are too large to fit in memory (allowed me to analyse an image of broken SD card).

The map is constantly updated during scan.

--
**Requirements:**
- Torch 7 (https://github.com/torch/torch7);
- Torch Image (https://github.com/torch/image);
- LuaFileSystem for files larger than 2 Gb (https://github.com/keplerproject/luafilesystem).

**License:**

Public domain.

**Usage:**

`th large_file_map.lua -sd "test.jpg" -size 580938 -image "out.png" -x 1024 -y 768`

- `-sd` – data file name;
- `-size` – data file size;
- `-image` – map image name;
- `-x` – map width;
- `-y` – map height.

**Possible problems:**
- If the size of source data file is wrong (on Windows or maybe on disks with "Advanced Format"), please set it manually with `-size N` option, in bytes.

--
Example image of 64 Gb SD card (1 pixel is ~63 kilobytes; the beginning contains files and the rest is probably empty):

![Example image of SD card.](https://github.com/VaKonS/large-file-map/raw/master/test.jpg)
