local orli = {}

---@param data string
---@param index integer
local function getByte(data, index)
	return data:sub(index, index):byte()
end

---@param data string
---@param index integer
local function getShort(data, index)
	return getByte(data, index)*256+getByte(data, index+1)
end

---@param data string
---@param index integer
local function getChar(data, index)
	return data:sub(index, index)
end

---@param byte integer
---@param colorBit integer
---@return integer
local function getColorLength(byte, colorBit)
	return bit32.rshift(bit32.lshift(byte, 32-8+colorBit), 32-8+colorBit)
end

---@param byte integer
---@param colorBit integer
---@return integer
local function getColor(byte, colorBit)
	return bit32.rshift(byte, 8-colorBit)
end

---@param str string
---@return integer[][], integer, integer
function orli.parse(str)
	if getByte(str, 1) ~= 153 or getChar(str, 2) ~= "O" or getChar(str, 3) ~= "R" or getChar(str, 4) ~= "L" or getChar(str, 5) ~= "I" then
		print(str:sub(1, 5))
		error("Data is not ORLI format")
	end
	local width, height = getShort(str, 6), getShort(str, 8)
	local colorCount = getByte(str, 10)
	local cols = {}
	local colorBit = math.max(math.ceil(math.log(colorCount, 2)), 1)
	local index = 11+colorCount
	for i = 11, 11+colorCount-1 do
		cols[#cols+1] = getChar(str, i)
	end

	local data = {}
	for y = 1, height do
		data[y] = {}
		for x = 1, width do
			data[y][x] = colors.red
		end
	end

	local j = 1
	for i = index, #str do
		local d = getByte(str, i)
		local l = getColorLength(d, colorBit)
		local c = getColor(d, colorBit)
		local col = cols[c+1]
		for j1 = j, j + l-1 do
			local x = (j1-1)%width+1
			local y = math.floor((j1-1)/width)+1
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