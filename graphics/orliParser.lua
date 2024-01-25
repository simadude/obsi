local orli = {}
local max, floor, ceil, log = math.max, math.floor, math.ceil, math.log
local brs, band = bit32.rshift, bit32.band
local sunpack = string.unpack
---@param data string
---@param index integer
local function getByte(data, index)
	return sunpack(">B", data, index)
end

---@param data string
---@param index integer
local function getShort(data, index)
	return sunpack(">H", data, index)
end

---@param data string
---@param index integer
local function getChar(data, index)
	return data:sub(index, index)
end

---@param byte integer
---@param lengthMask integer
---@return integer
local function getColorLength(byte, lengthMask)
	return band(byte, lengthMask)
end

---@param byte integer
---@param colorBit integer
---@return integer
local function getColor(byte, colorBit)
	return brs(byte, 8-colorBit)
end

---@param str string
---@return integer[][], integer, integer
function orli.parse(str)
	if str:sub(1, 5) ~= "\153ORLI" then
		print(str:sub(1, 5))
		error("Data is not the supported ORLI format")
	end
	local width, height = getShort(str, 6), getShort(str, 8)
	local colorCount = getByte(str, 10)
	local cols = {}
	local colorBit = max(ceil(log(colorCount, 2)), 1)
	local lengthMask = 2^(8-colorBit) - 1
	local index = 11+colorCount
	for i = 11, 11+colorCount-1 do
		cols[#cols+1] = getChar(str, i)
	end

	local data = {}
	for y = 1, height do
		data[y] = {}
		for x = 1, width do
			data[y][x] = colors.red -- In case when Orli is corrupted, we can quickly figure it out by having this as a default color.
		end
	end

	local j = 1
	for i = index, #str do
		local d = getByte(str, i)
		local l = getColorLength(d, lengthMask)
		local c = getColor(d, colorBit)
		local col = cols[c+1]
		for j1 = j, j + l-1 do
			local x = (j1-1)%width+1
			local y = floor((j1-1)/width)+1
			data[y][x] = tonumber(col, 16) and 2^tonumber(col, 16) or -1
		end
		j = j + l
		if j > width*height then
			-- yeah... either we got some data left over, or we don't have enough data.
			-- do I error here?
			break
		end
	end

	return data, width, height
end

return orli