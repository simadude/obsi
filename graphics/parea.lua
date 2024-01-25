local parea = {}
local floor = math.floor
local ceil = math.ceil
local concat = table.concat

---@type table<integer, string>
local toBlit = {}
for i = 0, 15 do
	toBlit[2^i] = ("%x"):format(i)
end

local function getBlit(color)
	return toBlit[color]
end

local function goodHeight(height)
	return ceil((height+2) / 2) * 3
end

local template = {}
---@param x integer
---@param y integer
---@param color color
function template:setPixel(x, y, color)
	self.data[y][x] = color
end

function template:render()
	local canvasdata = self.data
	local blit = self.term.blit
	local setCursorPos = self.term.setCursorPos
	local _, termHeight = self.term.getSize()
	termHeight = floor((termHeight+1)/2)*2
	if self.height % 3 ~= 0 or self.height ~= #self.data then
		error(("THE CANVAS IS WEIRD! CAN'T RENDER!\nself.height=%s, #self.data=%s"):format(self.height, #self.data))
	end
	local subposup = true
	-- local by = 1
	local y = 1
	local fgcoltab = {}
	local bgcoltab = {}
	for by = 1, termHeight do
		local txtstr = ""
		if subposup then
			txtstr = ("\143"):rep(self.width)
			for x = 1, self.width do
				fgcoltab[x] = getBlit(canvasdata[y][x])
				bgcoltab[x] = getBlit(canvasdata[y+1][x])
			end
		else
			txtstr = ("\131"):rep(self.width)
			for x = 1, self.width do
				fgcoltab[x] = getBlit(canvasdata[y-1][x])
				bgcoltab[x] = getBlit(canvasdata[y][x])
			end
		end
		setCursorPos(1, by)
		blit(txtstr, concat(fgcoltab), concat(bgcoltab))
		subposup = not subposup
		y = y + (subposup and 1 or 2)
	end
end

function template:resize(w, h)
	h = goodHeight(h)
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

---@param terminal Redirect?
---@param width integer?
---@param height integer?
function parea.newCanvas (terminal, width, height)
	---@class parea.Canvas
	local canvas = {}
	if (not width or not height) then
		if terminal then
			width, height = terminal.getSize()
		else
			width, height = term.getSize()
		end
	end
	-- God bless your soul if your terminal is 1 character in height, lol.
	height = goodHeight(height)

	canvas.width = width
	canvas.height = height
	canvas.term = terminal or term
	canvas.setPixel = template.setPixel
	canvas.resize = template.resize
	canvas.render = template.render
	canvas.owner = "parea"
	local data = {}
	for y = 1, height do
		data[y] = {}
		for x = 1, width do
			data[y][x] = colors.black
		end
	end
	---@type number[][]
	canvas.data = data

	return canvas
end

function parea.own(canvas)
	canvas.render = template.render
	canvas.resize = template.resize
	canvas.setPixel = template.setPixel
	canvas.owner = "parea"
end

return parea