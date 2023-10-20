--[[
	* api for easy interaction with drawing characters

	* single file implementation of GuiH pixelbox api

	* this version is very fast and ment for implementing into other apis
]]

-- Created by dev9551 (https://github.com/9551-Dev)
-- Edited by Sima to easily integrate with Obsi Game Engine and use with Lua Language Server (LLS)

local PIXELBOX = {}

---@class pixelbox.object
---@field width integer
---@field height integer
---@field data any
---@field term any
local OBJECT = {}

local t_sort,t_cat,s_char  = table.sort, table.concat, string.char
local function sort(a,b) return a[2] > b[2] end

local distances = {
	{5,256,16,8,64,32},
	{4,16,16384,256,128},
	[4]	={4,64,1024,256,128},
	[8]	={4,512,2048,256,1},
	[16]   ={4,2,16384,256,1},
	[32]   ={4,8192,4096,256,1},
	[64]   ={4,4,1024,256,1},
	[128]  ={6,32768,256,1024,2048,4096,16384},
	[256]  ={6,1,128,2,512,4,8192},
	[512]  ={4,8,2048,256,128},
	[1024] ={4,4,64,128,32768},
	[2048] ={4,512,8,128,32768},
	[4096] ={4,8192,32,128,32768},
	[8192] ={3,32,4096,256128},
	[16384]={4,2,16,128,32768},
	[32768]={5,128,1024,2048,4096,16384}
}

local to_blit = {}
for i = 0, 15 do
	to_blit[2^i] = ("%x"):format(i)
end

---@param BOX pixelbox.box
---@param color color
---@param width? integer
---@param height? integer
function PIXELBOX.RESTORE(BOX, color, width, height)
	local bc = {}
	if width then
		width = width * 2
		BOX.width = width
	else
		width = BOX.width
	end

	if height then
		height = height * 3
		BOX.height = height
	else
		height = BOX.height
	end

	for y = 1, height do
		for x = 1, width do
			if not bc[y] then bc[y] = {} end
			bc[y][x] = color
		end
	end

	BOX.data = bc
end

local function build_drawing_char(a,b,c,d,e,f)
	local arr = {a,b,c,d,e,f}
	local c_types = {}
	local sortable = {}
	local ind = 0
	for i=1,6 do
		local c = arr[i]
		if not c_types[c] then
			ind = ind + 1
			c_types[c] = {0,ind}
		end

		local t = c_types[c]
		local t1 = t[1] + 1

		t[1] = t1
		sortable[t[2]] = {c,t1}
	end
	local n = #sortable
	while n > 2 do
		t_sort(sortable,sort)
		local bit6 = distances[sortable[n][1]]
		local index,run = 1,false
		local nm1 = n - 1
		for i=2,bit6[1] do
			if run then break end
			local tab = bit6[i]
			for j=1,nm1 do
				if sortable[j][1] == tab then
					index = j
					run = true
					break
				end
			end
		end
		local from,to = sortable[n][1],sortable[index][1]
		for i=1,6 do
			if arr[i] == from then
				arr[i] = to
				local sindex = sortable[index]
				sindex[2] = sindex[2] + 1
			end
		end

		sortable[n] = nil
		n = n - 1
	end

	local n = 128
	local a6 = arr[6]

	if arr[1] ~= a6 then n = n + 1 end
	if arr[2] ~= a6 then n = n + 2 end
	if arr[3] ~= a6 then n = n + 4 end
	if arr[4] ~= a6 then n = n + 8 end
	if arr[5] ~= a6 then n = n + 16 end

	if sortable[1][1] == arr[6] then
		return s_char(n),sortable[2][1],arr[6]
	else
		return s_char(n),sortable[1][1],arr[6]
	end
end

function OBJECT:render()
	local t = self.term
	local blit_line, set_cursor = t.blit,t.setCursorPos

	local w_double = self.width
	local canv = self.data

	local sy = 0
	for y = 1, self.height, 3 do
		sy = sy + 1
		local layer_1 = canv[y]
		local layer_2 = canv[y+1]
		local layer_3 = canv[y+2]
		local char_line,fg_line,bg_line = {},{},{}
		local n = 0
		for x = 1, w_double, 2 do
			local xp1 = x+1
			local b11,b21,b12,b22,b13,b23 =
				layer_1[x],layer_1[xp1],
				layer_2[x],layer_2[xp1],
				layer_3[x],layer_3[xp1]

			local char, fg, bg = " ", 1, b11
			if not (b21 == b11
				and b12 == b11
				and b22 == b11
				and b13 == b11
				and b23 == b11) then
				char,fg,bg = build_drawing_char(b11,b21,b12,b22,b13,b23)
			end
			n = n + 1
			char_line[n] = char
			fg_line[n] = to_blit[fg]
			bg_line[n] = to_blit[bg]
		end

		set_cursor(1, sy)
		blit_line(t_cat(char_line), t_cat(fg_line), t_cat(bg_line))
	end
end


---@param BOX pixelbox.box
---@param width integer
---@param height integer
function PIXELBOX.RESIZE(BOX, width, height)
	local bc = BOX.data
	width = width * 2
	height = height * 3
	if BOX.height > height then
		for y = 1, BOX.height-height do
			table.remove(bc)
		end
	elseif BOX.height < height then
		for y = BOX.height, height do
			bc[y] = {}
			for x = 1, width do
				bc[y][x] = colors.black
			end
		end
	end
	if BOX.width > width then
		for y = 1, height do
			for x = 1, BOX.width-width-1 do
				table.remove(bc[y])
			end
		end
	elseif BOX.width < width then
		for y = 1, height do
			for x = BOX.width+1, width do
				bc[y][x] = colors.black
			end
		end
	end
	BOX.width = width
	BOX.height = height
end

---@param color color
function OBJECT:clear(color)
	PIXELBOX.RESTORE(self, color)
end

---@param x integer
---@param y integer
---@param color color
function OBJECT:setPixel(x, y, color)
	self.data[y][x] = color
end

---@param w integer
---@param h integer
function OBJECT:resize(w, h)
	PIXELBOX.RESIZE(self, w, h)
end

function PIXELBOX.own(canvas)
	canvas.clear = OBJECT.clear
	canvas.render = OBJECT.render
	canvas.resize = OBJECT.resize
	canvas.setPixel = OBJECT.setPixel
	canvas.owner = "pixelbox"
end

---@param terminal Redirect
---@param bg color?
---@return pixelbox.box
function PIXELBOX.new(terminal, bg)
	bg = bg or terminal.getBackgroundColor() or colors.black
	---@class pixelbox.box: pixelbox.object
	local BOX = {}
	local w, h = terminal.getSize()
	BOX.term = terminal
	BOX.clear = OBJECT.clear
	BOX.render = OBJECT.render
	BOX.resize = OBJECT.resize
	BOX.setPixel = OBJECT.setPixel
	BOX.width  = w * 2
	BOX.height = h * 3
	BOX.owner = "pixelbox"
	PIXELBOX.RESTORE(BOX, bg)
	return BOX
end

return PIXELBOX