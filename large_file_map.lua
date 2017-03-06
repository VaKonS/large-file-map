-- require 'lfs'   -- https://github.com/keplerproject/luafilesystem
require 'torch'    -- https://github.com/torch/torch7
require 'image'    -- https://github.com/torch/image

local cmd = torch.CmdLine()
cmd:text()
cmd:text('Makes visual file map.')
cmd:text()
cmd:option('-sd',           '', 'Source data file name.')
cmd:option('-size',          0, 'Data file size in bytes (if it was detected incorrectly).')
cmd:option('-image', 'out.png', 'Output image name.')
cmd:option('-x',          1366, 'Image width.')
cmd:option('-y',           768, 'Image height.')
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

  local dl
  if params.size > 0 then
    dl = params.size
  else
    dl = df:seek("end")
    if dl == -1 then
      -- Block size is assumed to be 512 bytes, how to detect it?
      local lfs = require 'lfs'
      dl = math.floor(512 * lfs.attributes(params.sd, 'blocks') / 4294967296) * 4294967296 + (lfs.attributes(params.sd, 'size') + 4294967296) % 4294967296
    end
  end

  local cnt = params.x * params.y * 3
  local cl = math.ceil(dl / cnt)
  if cl < 1 then cl = 1 end  -- if file has 0 length
  print("File: \"" .. params.sd .. "\"\n" .. dl .. plural_bytes(dl) .. ", averaging length: " .. cl .. plural_bytes(cl) .. ".")

  -- serialized torch.ByteTensor(cl) template without data, to not recalculate it every time
  local bt_tp_cl = string.sub(torch.serialize(torch.ByteTensor(cl), 'binary'), 1, (-1 - cl))

  local img = torch.DoubleTensor(3, params.y, params.x):zero()
  df:seek("set")
  local ci = 0

  -- It seems that 32-bit Lua v5.2 produces times like this:
  -- 0 ... 2147.483647, -2147.483648 ... 2147.483647, -2147.483648...
  -- (32-bit signed counter of microseconds),
  -- therefore the counter should be corrected
  -- to measure intervals longer than 2147.5 seconds.
  local clock_round = 0
  local clock_current = 0
  local clock_previous = -2148

  print('Starting...')
  local clock_start = os.clock()

  for y = 1, params.y do
  for x = 1, params.x do
  for i = 1, 3 do
    local c = df:read(cl)
    if c ~= nil then
      local ser_tensor
      if #c == cl then
        ser_tensor = bt_tp_cl .. c
      else
        ser_tensor = string.sub(torch.serialize(torch.ByteTensor(#c), 'binary'), 1, (-1 - #c)) .. c
      end
      img[i][y][x] = torch.deserialize(ser_tensor, 'binary'):double():mean() / 255

      ci = ci + 1
      if (i == 1) and (x == 1) then
        clock_current = os.clock()
        if clock_current < clock_previous then clock_round = clock_round + 1 end
        clock_previous = clock_current
        print(string.format('\027[1A\027[K\027[1000D%1.3f%%, %1.1f seconds remaining.', ci / cnt * 100, (clock_round * 4294.967296 + clock_current - clock_start) / ci * (cnt - ci)))
        image.save(params.image, img)
      end
    end
  end
  end
  end
  clock_current = os.clock()
  if clock_current < clock_previous then clock_round = clock_round + 1 end
  print(string.format('\027[1A\027[K\027[1000D100%%, %1.1f seconds.', (clock_round * 4294.967296 + clock_current - clock_start)))

  df:close()
  image.save(params.image, img:clamp(0, 1))
end


local params = cmd:parse(arg)
main(params)
