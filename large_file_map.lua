-- require 'lfs'   -- https://github.com/keplerproject/luafilesystem
require 'torch'    -- https://github.com/torch/torch7
require 'image'    -- https://github.com/torch/image

local cmd = torch.CmdLine()
cmd:text()
cmd:text('Makes visual file map.')
cmd:text()
cmd:option('-sd', '',
           'Source data file.')
cmd:option('-image', 'out.png',
           'Output image file.')
cmd:option('-x', 1366,
           'Output image width.')
cmd:option('-y', 768,
           'Output image height.')
cmd:text()


local function plural_bytes(n)
  local b
  if n == 1 then b = ' byte' else b = ' bytes' end
  return b
end


local function main(params)
  if params.sd == '' then
    print("\nInput data file is not given.\n")
    os.exit()
  end
  local df = io.open(params.sd, "r")
  if df == nil then
    print("\nCan not open file: \"" .. params.sd .. "\".\n")
    os.exit()
  end

  local dl = df:seek("end")
  if dl == -1 then
    -- Block size is assumed to be 512 bytes, how to detect it?
    local lfs = require 'lfs'
    dl = math.floor(512 * lfs.attributes(params.sd, 'blocks') / 4294967296) * 4294967296 + (lfs.attributes(params.sd, 'size') + 4294967296) % 4294967296
  end

  local cnt = params.x * params.y * 3
  local cl = math.ceil(dl / cnt)
  if cl < 1 then cl = 1 end
  print("File: \"" .. params.sd .. "\"\n" .. dl .. plural_bytes(dl) .. ", averaging length: " .. cl .. plural_bytes(cl) .. ".\n")

  local img = torch.DoubleTensor(3, params.y, params.x):zero()
  df:seek("set")
  local ci = 0
  local sc = os.clock()
  for y = 1, params.y do
  for x = 1, params.x do
  for i = 1, 3 do
    local c = df:read(cl)
    if c ~= nil then
      -- Torch 7 tensor format: 4,1,3,"V 1",16,"torch.ByteTensor",1,len,1,1,4,2,3,"V 1",17,"torch.ByteStorage",len,data
      local lcl = #c
      local lclb = string.char((lcl % 256), (bit32.rshift(lcl, 8) % 256), (bit32.rshift(lcl, 16) % 256), (bit32.rshift(lcl, 24) % 256))
      local t = torch.deserialize("\4\0\0\0\1\0\0\0\3\0\0\0V 1\16\0\0\0torch.ByteTensor\1\0\0\0" .. lclb .. "\1\0\0\0\1\0\0\0\4\0\0\0\2\0\0\0\3\0\0\0V 1\17\0\0\0torch.ByteStorage" .. lclb .. c)
      -- print(#t)
      -- print(t)
      img[i][y][x] = t:double():mean() / 255

      ci = ci + 1
      if (i == 1) and (x == 1) then
        print(string.format('\027[1A\027[K\027[1000D%1.3f%%, %1.1f seconds remain', ci / cnt * 100, (os.clock() - sc) / ci * (cnt - ci)))
        image.save(params.image, img)
      end
    end
  end
  end
  end
  print(string.format('\027[1A\027[K\027[1000D100%%, %1.3f seconds.', (os.clock() - sc)))

  df:close()
  image.save(params.image, img:clamp(0, 1))
end


local params = cmd:parse(arg)
main(params)
