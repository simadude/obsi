local hmon = {}
local concat = table.concat

---@type table<integer, string>
local toBlit = {}
for i = 0, 15 do
	toBlit[2^i] = ("%x"):format(i)
end

local function getBlit(color)
	return toBlit[color]
end

---@param terminal Redirect?
---@param width integer?
---@param height integer?
function hmon.newCanvas (terminal, width, height)
	---@class hmon.Canvas
	local canvas = {}
	if (not width or not height) then
		if terminal then
			width, height = terminal.getSize()
		else
			width, height = term.getSize()
		end
	end

	canvas.width = width
	canvas.height = height
	canvas.term = terminal or term
	local data = {}
	for y = 1, height do
		data[y] = {}
		for x = 1, width do
			data[y][x] = colors.black
		end
	end
	---@type number[][]
	canvas.data = data

	---@param x integer
	---@param y integer
	---@param color color
	function canvas:setPixel(x, y, color)
		if y > #self.data then
			error(("y: %s, max: %s"):format(y, #self.data))
		end
		self.data[y][x] = color
	end
	function canvas:render()
		local canvasdata = self.data
		local blit = self.term.blit
		local setCursorPos = self.term.setCursorPos
		local fgcol = ("0"):rep(self.width)
		local txtstr = (" "):rep(self.width)
		local bgcoltab = {}
		for by = 1, canvas.height do
			for x = 1, self.width do
				bgcoltab[x] = getBlit(canvasdata[by][x])
			end
			setCursorPos(1, by)
			blit(txtstr, fgcol, concat(bgcoltab))
		end
	end
	function canvas:resize(w, h)
		if self.height > h then
			for y = 1, self.height-h do
				table.remove(self.data)
			end
		elseif self.height < h then
			for y = self.height, h do
				self.data[y] = {}
				for x = 1, w do
					self.data[y][x] = colors.black
				end
			end
		end
		if self.width > w then
			for y = 1, h do
				for x = 1, self.width-w-1 do
					table.remove(self.data[y])
				end
			end
		elseif self.width < w then
			for y = 1, h do
				for x = self.width+1, w do
					self.data[y][x] = colors.black
				end
			end
		end
		self.width = w
		self.height = h
	end
	return canvas
end

hmon.getBlit = getBlit

return hmon