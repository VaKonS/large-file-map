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
cmd:option('-u',            16, 'Update image every N lines (faster).')
cmd:text()


local params = cmd:parse(arg)

local function plural_bytes(n)
  local b
  if n == 1 then b = ' byte' else b = ' bytes' end
  return b
end

-- In 32-bit Lua v5.2 time counter should be corrected if program is running longer than 2147.5 seconds.
local lua52_time_corrector_clock_round, lua52_time_corrector_clock_previous = 0, -2148
local function Lua52CorrectedTime()
-- Call it instead of os.clock(). Must be called more often than every 4294 seconds (~1h 11,5m).
  local clock_current = os.clock()
  if clock_current < lua52_time_corrector_clock_previous then lua52_time_corrector_clock_round = lua52_time_corrector_clock_round + 1 end
  lua52_time_corrector_clock_previous = clock_current
  return lua52_time_corrector_clock_round * 4294.967296 + clock_current
end


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

  local cnt = params.x * params.y
  local cl = math.ceil(dl / cnt)
  if cl < 1 then cl = 1 end  -- if file has 0 length
  print("File: \"" .. params.sd .. "\"\n" .. dl .. plural_bytes(dl) .. ", 1 pixel = " .. cl .. plural_bytes(cl) .. ".")

  -- serialized torch.ByteTensor(cl) template without data, to not recalculate it every time
  local bt_tp_cl = string.sub(torch.serialize(torch.ByteTensor(cl), 'binary'), 1, (-1 - cl))

  local img = torch.DoubleTensor(3, params.y, params.x):zero()
  df:seek("set")
  local ci = 0

  print('Starting...')
  local clock_start = os.time(os.date("!*t"))

  for y = 1, params.y do
  for x = 1, params.x do
    local c = df:read(cl)
    if c ~= nil then
      local ser_tensor
      if #c == cl then
        ser_tensor = bt_tp_cl .. c
      else
        ser_tensor = string.sub(torch.serialize(torch.ByteTensor(#c), 'binary'), 1, (-1 - #c)) .. c
      end
      img[{{}, y, x}] = torch.deserialize(ser_tensor, 'binary'):view(1, -1):expand(3, #c):t():contiguous():view(3, -1):double():mean(2):div(255)

      ci = ci + 1
      if (x == 1) then
        print(string.format('\027[1A\027[K\027[1000D%1.3f%%, %1.1f seconds remaining.', ci / cnt * 100, os.difftime(os.time(os.date("!*t")), clock_start) / ci * (cnt - ci)))
        if (y % params.u) == 0 then
          image.save(params.image, img)
        end
      end
    end
  end
  end
  print(string.format('\027[1A\027[K\027[1000D100%%, %1.1f seconds.', os.difftime(os.time(os.date("!*t")), clock_start)))

  df:close()
  print("Writing \"" .. params.image .. "\".\n")
  image.save(params.image, img:clamp(0, 1))

  os.exit()
