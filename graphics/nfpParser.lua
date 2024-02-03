local nfp = {}

---Takes inconsistent 2D array as an argument and returns a consistent one instead.
---@param badData integer[][]
---@param width integer
---@param height integer
---@return integer[][]
function nfp.consise(badData, width, height)
	local goodData = {}
	for y = 1, height do
		goodData[y] = {}
		for x = 1, width do
			goodData[y][x] = badData[y] and badData[y][x] or -1
		end
	end
	return goodData
end

---@param text string
---@return integer[][]
function nfp.parseNFP(text)
	local x, y = 1, 1
	local width = 0
	local data = {}
	for i = 1, #text do
		local char = text:sub(i, i)
		if not tonumber(char, 16) and char ~= "\n" and char ~= " " then
			error(("Unknown character (%s) at %s\nMake sure your image is valid .nfp"):format(char, i))
		end
		if char == "\n" then
			y = y + 1
			x = 1
		else
			if not data[y] then
				data[y] = {}
			end
			data[y][x] = (char == " ") and -1 or 2^tonumber(char, 16)
			width = math.max(width, x)
			x = x + 1
		end
	end

	return nfp.consise(data, width, y)
end

return nfp