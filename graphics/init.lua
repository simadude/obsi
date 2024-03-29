local filesystem
local parea = require("graphics.parea")
local pixelbox = require("graphics.pixelbox")
local nfp = require("graphics.nfpParser")
local orli = require("graphics.orliParser")
local hmon = require("graphics.hmon")
local wind = window.create(term.current(), 1, 1, term.getSize())
wind.setVisible(false)

---@class obsi.graphics
local graphics = {}

local floor, ceil, abs, max = math.floor, math.ceil, math.abs, math.max

---@type parea.Canvas|pixelbox.box
local internalCanvas
---@type obsi.Canvas|pixelbox.box|parea.Canvas
local currentCanvas

---@class obsi.TextPiece
---@field x integer
---@field y integer
---@field text string
---@field fgColor string?
---@field bgColor string?

---@type obsi.TextPiece[]
local textBuffer = {}

graphics.originX = 1
graphics.originY = 1

graphics.width, graphics.height = term.getSize()

graphics.fgColor = colors.white
graphics.bgColor = colors.black

---@param value any
---@param expectedType type
---@param paramName string
local function checkType(value, expectedType, paramName)
	if type(value) ~= expectedType then
		error(("Argument '%s' must be a %s, not a %s"):format(paramName, expectedType, type(value)), 3)
	end
end

---@type table<integer, string>
local toBlit = {}
for i = 0, 15 do
	toBlit[2^i] = ("%x"):format(i)
end

local function getBlit(color)
	return toBlit[color]
end

---Sets a specific palette color
---@param color string|color
---@param r number value within the range [0-1]
---@param g number value within the range [0-1]
---@param b number value within the range [0-1]
function graphics.setPaletteColor(color, r, g, b)
	if type(color) == "string" then
		if #color ~= 1 then
			error(("Argument `color: string` must be 1 character long, not %s"):format(#color))
		end
		color = tonumber(color, 16)
		if not color then
			error(("Argument `color: string` must be a valid hex character, not %s"):format(color))
		end
		color = 2^color
	elseif type(color) ~= "number" then
		error(("Argument `color` must be either integer or string, not %s"):format(type(color)))
	end
	checkType(r, "number", "r")
	checkType(g, "number", "g")
	checkType(b, "number", "b")
	wind.setPaletteColor(color, r, g, b)
end

---@param x integer
---@param y integer
function graphics.offsetOrigin(x, y)
	checkType(x, "number", "x")
	checkType(y, "number", "y")
	graphics.originX = graphics.originX + floor(x)
	graphics.originY = graphics.originY + floor(y)
end

---@param x integer
---@param y integer
function graphics.setOrigin(x, y)
	checkType(x, "number", "x")
	checkType(y, "number", "y")
	graphics.originX = floor(x)
	graphics.originY = floor(y)
end

function graphics.resetOrigin()
	graphics.originX = 1
	graphics.originY = 1
end

---@return integer, integer
function graphics.getOrigin()
	return graphics.originX, graphics.originY
end

function graphics.getPixelWidth()
	return graphics.pixelWidth
end

function graphics.getPixelHeight()
	return graphics.pixelHeight
end

function graphics.getWidth()
	return graphics.width
end

function graphics.getHeight()
	return graphics.height
end

function graphics.getSize()
	return graphics.width, graphics.height
end

function graphics.getPixelSize()
	return graphics.pixelWidth, graphics.pixelHeight
end

function graphics.termToPixelCoordinates(x, y)
	if internalCanvas.owner == "hmon" then
		return x, y
	elseif internalCanvas.owner == "parea" then
		return x, floor(y*1.5)
	elseif internalCanvas.owner == "pixelbox" then
		return x*2, y*3
	end
end

function graphics.pixelToTermCoordinates(x, y)
	if internalCanvas.owner == "hmon" then
		return x, y
	elseif internalCanvas.owner == "parea" then
		return x, floor(y/1.5)
	elseif internalCanvas.owner == "pixelbox" then
		return floor(x/2), floor(y/3)
	end
end

---@param col color|string
---@return color
local function toColor(col)
	if type(col) == "string" then
		return 2^tonumber(col, 16)
	end
	return col
end

---@param color color|string
function graphics.setBackgroundColor(color)
	graphics.bgColor = toColor(color)
end

---@param color color|string
function graphics.setForegroundColor(color)
	graphics.fgColor = toColor(color)
end

---@return color
function graphics.getBackgroundColor()
	return graphics.bgColor
end

---@return color
function graphics.getForegroundColor()
	return graphics.fgColor
end

---@param x number
---@param y number
---@return boolean
local function inBounds(x, y)
	return (x >= 1) and (y >= 1) and (x <= currentCanvas.width) and (y <= currentCanvas.height)
end

---@param x number
---@param y number
---@param color? color
local function safeOffsetPixel(x, y, color)
	color = color or graphics.fgColor
	x, y = floor(x-graphics.originX+1), floor(y-graphics.originY+1)
	if inBounds(x, y) then
		currentCanvas:setPixel(x, y, color)
	end
end

---@param x number
---@param y number
function graphics.point(x, y)
	checkType(x, "number", "x")
	checkType(y, "number", "y")

	safeOffsetPixel(x, y)
end

---@param points table[]
function graphics.points(points)
	for i = 1, #points do
		local point = points[i]
		safeOffsetPixel(point[1], point[2])
	end
end

---@param mode "fill"|"line"
---@param x integer
---@param y integer
---@param width integer
---@param height integer
function graphics.rectangle(mode, x, y, width, height)
	checkType(x, "number", "x")
	checkType(y, "number", "y")
	checkType(width, "number", "width")
	checkType(height, "number", "height")

	if mode == "fill" then
		for ry = y, y+height-1 do
			for rx = x, x+width-1 do
				safeOffsetPixel(rx, ry)
			end
		end
	elseif mode == "line" then
		for ry = y, y+height-1 do
			safeOffsetPixel(x, ry)
		end
		for ry = y, y+height-1 do
			safeOffsetPixel(x+width-1, ry)
		end
		for rx = x, x+width-1 do
			safeOffsetPixel(rx, y)
		end
		for rx = x, x+width-1 do
			safeOffsetPixel(rx, y+height-1)
		end
	end
end

function graphics.line(point1, point2)
	local x1, y1 = floor(point1[1]), floor(point1[2])
	local x2, y2 = floor(point2[1]), floor(point2[2])
	local dx, dy = abs(x2-x1), abs(y2-y1)
	local sx, sy = (x1 < x2) and 1 or -1, (y1 < y2) and 1 or -1
	local err = dx-dy
	while x1 ~= x2 or y1 ~= y2 do
		safeOffsetPixel(x1, y1)
		local err2 = err * 2
		if err2 > -dy then
			err = err - dy
			x1 = x1 + sx
		end
		if err2 < dx then
			err = err + dx
			y1 = y1 + sy
		end
	end
	safeOffsetPixel(x2, y2)
end

---@class obsi.Image
---@field data integer[][]
---@field width integer
---@field height integer

local function getCorrectImage(imagePath, contents)
	local image = {}
	local data, width, height
	--- Parse images
	if imagePath:sub(-4):lower() == ".nfp" then
		data = nfp.parseNFP(contents)
		width, height = #data[1], #data
	elseif imagePath:sub(-5):lower() == ".orli" then
		data, width, height = orli.parse(contents)
	else
		error(("Extension of the image is not supported: %s"):format(imagePath), 2)
	end
	image.data = data
	image.width = width
	image.height = height
	return image
end

---@param imagePath path
---@return obsi.Image
function graphics.newImage(imagePath)
	local contents, e = filesystem.read(imagePath)
	if not contents then
		error(e)
	end
	local image = getCorrectImage(imagePath, contents)
	return image
end

---Returns a blank obsi.Image with a solid color. 
---@param width integer
---@param height integer
---@param filler? color|string
---@return obsi.Image
function graphics.newBlankImage(width, height, filler)
	checkType(width, "number", "width")
	checkType(height, "number", "height")

	filler = filler and toColor(filler) or -1
	width = floor(max(width, 1))
	height = floor(max(height, 1))

	local image = {}
	image.data = {}
	for y = 1, height do
		image.data[y] = {}
		for x = 1, width do
			image.data[y][x] = filler
		end
	end
	image.width = width
	image.height = height

	return image
end


---Returns an array of obsi.Image objects that represent the tiles on the Tilemap.
---@param imagePath path
---@return obsi.Image[]
function graphics.newImagesFromTilesheet(imagePath, tileWidth, tileHeight)
	local contents, e = filesystem.read(imagePath)
	if not contents then
		error(e)
	end
	local map = getCorrectImage(imagePath, contents)

	if map.width % tileWidth ~= 0 then
		error(("Tilemap width can't be divided by tile's width: %s and %s"):format(map.width, tileWidth))
	elseif map.height % tileHeight ~= 0 then
		error(("Tilemap height can't be divided by tile's height: %s and %s"):format(map.height, tileHeight))
	end

	local images = {}

	for ty = tileHeight, map.height, tileHeight do
		for tx = tileWidth, map.width, tileWidth do
			local image = graphics.newBlankImage(tileWidth, tileHeight, -1)
			for py = 1, tileHeight do
				for px = 1, tileWidth do
					image.data[py][px] = map.data[ty-tileHeight+py][tx-tileWidth+px]
				end
			end
			images[#images+1] = image
		end
	end

	return images
end

---Creates a new obsi.Canvas object.
---@param width integer?
---@param height integer?
---@return obsi.Canvas
function graphics.newCanvas(width, height)
	width, height = floor(width or internalCanvas.width), floor(height or internalCanvas.height)

	---@class obsi.Canvas
	local canvas = {}
	canvas.width = width
	canvas.height = height
	canvas.data = {}
	for y = 1, height do
		canvas.data[y] = {}
		for x = 1, width do
			canvas.data[y][x] = colors.black
		end
	end

	---@param self obsi.Canvas
	---@param x integer
	---@param y integer
	---@param color color
	canvas.setPixel = function (self, x, y, color)
		self.data[y][x] = color
	end

	---@param self table
	---@param x integer
	---@param y integer
	---@return color
	canvas.getPixel = function (self, x, y)
		return self.data[y][x]
	end

	canvas.clear = function(self)
		for y = 1, self.height do
			for x = 1, self.width do
				self.data[y][x] = graphics.bgColor
			end
		end
	end

	return canvas
end

---@param image obsi.Image
---@param x integer
---@param y integer
local function drawNoScale(image, x, y)
	local data = image.data
	for iy = 1, image.height do
		for ix = 1, image.width do
			if not data[iy] then
				error(("iy: %s, #image.data: %s"):format(iy, #data))
			end
			local pix = data[iy][ix]
			if pix > 0 then
				safeOffsetPixel(x+ix-1, y+iy-1, pix)
			end
		end
	end
end

---Draws an obsi.Image or obsi.Canvas at certain coordinates.
---@param image obsi.Image|obsi.Canvas
---@param x integer x position
---@param y integer y position
---@param sx? number x scale
---@param sy? number y scale
function graphics.draw(image, x, y, sx, sy)
	checkType(x, "number", "x")
	checkType(y, "number", "y")
	sx = sx or 1
	sy = sy or 1

	-- check if the image out of the screen or if it's too small to be drawn
	if sx == 0 or sy == 0 then
		return
	elseif (sx > 0 and x-graphics.originX+1 > currentCanvas.width) or (sy > 0 and y-graphics.originY+1 > currentCanvas.height) then
		return
	end

	-- a little optimization to not bother with scaling
	if sx == 1 and sy == 1 then
		drawNoScale(image, x, y)
		return
	end
	local signsx = abs(sx)/sx
	local signsy = abs(sy)/sy
	sx = abs(sx)
	sy = abs(sy)
	-- variable naming:
	-- i_ - iterative variable
	-- p_ - pixel position on the image
	-- s_ - scale for each axis

	for iy = 1, image.height*sy do
		local py = ceil(iy/sy)
		for ix = 1, image.width*sx do
			local px = ceil(ix/sx)
			if not image.data[py] then
				error(("py: %s, #image.data: %s"):format(py, #image.data))
			end
			local pix = image.data[py][px]
			if pix > 0 then
				safeOffsetPixel(x+ix*signsx-signsx, y+iy*signsy-signsy, pix)
			end
		end
	end
end

--- Writes a text on the terminal.
---
--- Beware that it uses terminal coordinates and not pixel coordinates.
---@param text string
---@param x integer
---@param y integer
---@param fgColor? string|color
---@param bgColor? string|color
function graphics.write(text, x, y, fgColor, bgColor)
	checkType(text, "string", "text")
	checkType(x, "number", "x")
	checkType(y, "number", "y")
	local textPiece = {}
	textPiece.text = text
	textPiece.x = x
	textPiece.y = y

	fgColor = fgColor or graphics.fgColor
	bgColor = bgColor or graphics.bgColor

	if type(fgColor) == "number" then
		fgColor = getBlit(fgColor):rep(#text)
	elseif type(fgColor) == "string" and #fgColor == 1 then
		fgColor = fgColor:rep(#text)
	end
	---@cast fgColor string|nil

	if type(bgColor) == "number" then
		bgColor = getBlit(bgColor):rep(#text)
	elseif type(bgColor) == "string" and #bgColor == 1 then
		bgColor = bgColor:rep(#text)
	end
	---@cast bgColor string|nil

	if type(fgColor) ~= "string" then
		error("fgColor is not a number or a string!")
	elseif type(bgColor) ~= "string" then
		error("bgColor is not a number or a string!")
	end

	textPiece.fgColor = fgColor
	textPiece.bgColor = bgColor

	textBuffer[#textBuffer+1] = textPiece
end

---@class obsi.Palette
---@field data number[][]

---Creates a new obsi.Palette object.
---@param palettePath path
---@return obsi.Palette
function graphics.newPalette(palettePath)
	checkType(palettePath, "string", "palettePath")
	local fh, e = filesystem.newFile(palettePath, "r")
	if not fh then
		error(e)
	end

	local cols = {}
	for i = 1, 16 do
		local line = fh.file.readLine()
		if not line then
			error("File could not be read completely!")
		end
		local occurrences = {}
		for str in line:gmatch("%d+") do
			if not tonumber(str) then
				error(("Can't put %s as a number"):format(str))
			end
			occurrences[#occurrences+1] = tonumber(str)
		end
		if #occurrences > 3 then
			error("More colors than should be possible!")
		end
		cols[i] = {table.unpack(occurrences)}
	end

	fh:close()
	return {data = cols}
end

---@param palette obsi.Palette
function graphics.setPalette(palette)
	for i = 1, 16 do
		local colors = palette.data[i]
		wind.setPaletteColor(2^(i-1), colors[1]/255, colors[2]/255, colors[3]/255)
	end
end

function graphics.clearPalette()
	shell.run("clear", "palette")
end

---@param canvas obsi.Canvas|nil
function graphics.setCanvas(canvas)
	currentCanvas = canvas or internalCanvas
end

---@return obsi.Canvas
function graphics.getCanvas()
	return currentCanvas
end

---Internal function that clears the canvas.
function graphics.clear()
	for y = 1, currentCanvas.height do
		for x = 1, currentCanvas.width do
			currentCanvas:setPixel(x, y, graphics.bgColor)
		end
	end
end

---@param rend "parea"|"hmon"|"pixelbox"
function graphics.setRenderer(rend)
	local tab = {
		["parea"] = parea,
		["hmon"] = hmon,
		["pixelbox"] = pixelbox,
	}
	local renderer = tab[rend]
	if renderer then
		renderer.own(internalCanvas)
		local w, h = graphics.getSize()
		internalCanvas:resize(w, h)
		graphics.pixelWidth, graphics.pixelHeight = internalCanvas.width, internalCanvas.height
	else
		error(("Unknown renderer name: %s"):format(rend))
	end
end

function graphics.getRenderer()
	return internalCanvas.owner
end

---Internal function that draws the canvas.
function graphics.flushCanvas()
	internalCanvas:render()
end

---Internal function that draws all the texts.
function graphics.flushText()
	for i = 1, #textBuffer do
		local textPiece = textBuffer[i]
		local text = textPiece.text
		if textPiece.x+#text >= 1 and textPiece.y >= 1 and textPiece.x <= graphics.getWidth() and textPiece.y <= graphics.getHeight() then
			wind.setCursorPos(textPiece.x, textPiece.y)
			wind.blit(text, textPiece.fgColor or getBlit(graphics.fgColor):rep(#text), textPiece.bgColor or getBlit(graphics.bgColor):rep(#text))
		end
	end
	textBuffer = {}
end

function graphics.flushAll()
	graphics.flushCanvas()
	graphics.flushText()
end

function graphics.show()
	wind.setVisible(true)
	wind.setVisible(false)
end

return function (obsifilesystem, renderingAPI)
	if renderingAPI == "parea" then
		internalCanvas = parea.newCanvas(wind)
	elseif renderingAPI == "hmon" then
		internalCanvas = hmon.newCanvas(wind)
	elseif renderingAPI == "pixelbox" then
		internalCanvas = pixelbox.new(wind)
	end
	graphics.pixelWidth, graphics.pixelHeight = internalCanvas.width, internalCanvas.height
	currentCanvas = internalCanvas
	filesystem = obsifilesystem
	return graphics, internalCanvas, wind
end