local pixelbox = {}

pixelbox.license = [[MIT License

Copyright (c) 2022 Oliver Caha

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- Created by dev9551 (https://github.com/9551-Dev)
-- Edited by Sima to easily integrate with Obsi Game Engine and use with Lua Language Server (LLS)

local box_object = {}

local t_cat  = table.concat

local sampling_lookup = {
	{2,3,4,5,6},
	{4,1,6,3,5},
	{1,4,5,2,6},
	{2,6,3,5,1},
	{3,6,1,4,2},
	{4,5,2,3,1}
}

local texel_character_lookup  = {}
local texel_foreground_lookup = {}
local texel_background_lookup = {}
local to_blit = {}

local function generate_identifier(s1,s2,s3,s4,s5,s6)
	return  s2 * 1 +
			s3 * 3 +
			s4 * 4 +
			s5 * 20 +
			s6 * 100
end

local function calculate_texel(v1,v2,v3,v4,v5,v6)
	local texel_data = {v1,v2,v3,v4,v5,v6}

	local state_lookup = {}
	for i=1,6 do
		local subpixel_state = texel_data[i]
		local current_count = state_lookup[subpixel_state]

		state_lookup[subpixel_state] = current_count and current_count + 1 or 1
	end

	local sortable_states = {}
	for k,v in pairs(state_lookup) do
		sortable_states[#sortable_states+1] = {
			value = k,
			count = v
		}
	end

	table.sort(sortable_states,function(a,b)
		return a.count > b.count
	end)

	local texel_stream = {}
	for i=1,6 do
		local subpixel_state = texel_data[i]

		if subpixel_state == sortable_states[1].value then
			texel_stream[i] = 1
		elseif subpixel_state == sortable_states[2].value then
			texel_stream[i] = 0
		else
			local sample_points = sampling_lookup[i]
			for sample_index=1,5 do
				local sample_subpixel_index = sample_points[sample_index]
				local sample_state		  = texel_data   [sample_subpixel_index]

				local common_state_1 = sample_state == sortable_states[1].value
				local common_state_2 = sample_state == sortable_states[2].value

				if common_state_1 or common_state_2 then
					texel_stream[i] = common_state_1 and 1 or 0

					break
				end
			end
		end
	end

	local char_num = 128
	local stream_6 = texel_stream[6]
	if texel_stream[1] ~= stream_6 then char_num = char_num + 1  end
	if texel_stream[2] ~= stream_6 then char_num = char_num + 2  end
	if texel_stream[3] ~= stream_6 then char_num = char_num + 4  end
	if texel_stream[4] ~= stream_6 then char_num = char_num + 8  end
	if texel_stream[5] ~= stream_6 then char_num = char_num + 16 end

	local state_1,state_2
	if #sortable_states > 1 then
		state_1 = sortable_states[  stream_6+1].value
		state_2 = sortable_states[2-stream_6  ].value
	else
		state_1 = sortable_states[1].value
		state_2 = sortable_states[1].value
	end

	return char_num,state_1,state_2
end

local function base_n_rshift(n,base,shift)
	return math.floor(n/(base^shift))
end

local real_entries = 0
local function generate_lookups()
	for i = 0, 15 do
		to_blit[2^i] = ("%x"):format(i)
	end

	for encoded_pattern=0,6^6 do
		local subtexel_1 = base_n_rshift(encoded_pattern,6,0) % 6
		local subtexel_2 = base_n_rshift(encoded_pattern,6,1) % 6
		local subtexel_3 = base_n_rshift(encoded_pattern,6,2) % 6
		local subtexel_4 = base_n_rshift(encoded_pattern,6,3) % 6
		local subtexel_5 = base_n_rshift(encoded_pattern,6,4) % 6
		local subtexel_6 = base_n_rshift(encoded_pattern,6,5) % 6

		local pattern_lookup = {}
		pattern_lookup[subtexel_6] = 5
		pattern_lookup[subtexel_5] = 4
		pattern_lookup[subtexel_4] = 3
		pattern_lookup[subtexel_3] = 2
		pattern_lookup[subtexel_2] = 1
		pattern_lookup[subtexel_1] = 0

		local pattern_identifier = generate_identifier(
			pattern_lookup[subtexel_1],pattern_lookup[subtexel_2],
			pattern_lookup[subtexel_3],pattern_lookup[subtexel_4],
			pattern_lookup[subtexel_5],pattern_lookup[subtexel_6]
		)

		if not texel_character_lookup[pattern_identifier] then
			real_entries = real_entries + 1
			local character,sub_state_1,sub_state_2 = calculate_texel(
				subtexel_1,subtexel_2,
				subtexel_3,subtexel_4,
				subtexel_5,subtexel_6
			)

			local color_1_location = pattern_lookup[sub_state_1] + 1
			local color_2_location = pattern_lookup[sub_state_2] + 1

			texel_foreground_lookup[pattern_identifier] = color_1_location
			texel_background_lookup[pattern_identifier] = color_2_location

			texel_character_lookup[pattern_identifier] = string.char(character)
		end
	end
end

---@param box table
---@param color color
---@param keep_existing? boolean
function pixelbox.restore(box, color, keep_existing)
	if not keep_existing then
		local new_canvas = {}

		for y = 1, box.height do
			if not new_canvas[y] then new_canvas[y] = {} end
			for x = 1, box.width do
				new_canvas[y][x] = color
			end
		end

		box.data = new_canvas
	else
		local canvas = box.data

		for y = 1, box.height do
			if not canvas[y] then canvas[y] = {} end
			for x = 1, box.width do
				if not canvas[y][x] then
					canvas[y][x] = color
				end
			end
		end
		if #box.data > box.height then
			for _ = 1, #box.data - box.height do
				table.remove(box.data)
			end
		end
	end
end

local color_lookup  = {}
local texel_body = {0,0,0,0,0,0}

function box_object:render()
	local t = self.term
	local blit_line,set_cursor = t.blit, t.setCursorPos
	local canv = self.data
	local char_line, fg_line, bg_line = {}, {}, {}
	local width = self.width

	local sy = 0
	for y = 1, self.height, 3 do
		sy = sy + 1
		local layer_1 = canv[y]
		local layer_2 = canv[y+1]
		local layer_3 = canv[y+2]

		local n = 0
		for x = 1, width-1, 2 do
			local xp1 = x+1
			local b1, b2, b3, b4, b5, b6 = layer_1[x], layer_1[xp1], layer_2[x], layer_2[xp1], layer_3[x], layer_3[xp1]

			local char, fg, bg = " ", 1, b1

			local single_color = b2 == b1 and b3 == b1 and b4 == b1 and b5 == b1 and b6 == b1

			if not single_color then
				color_lookup[b6] = 5
				color_lookup[b5] = 4
				color_lookup[b4] = 3
				color_lookup[b3] = 2
				color_lookup[b2] = 1
				color_lookup[b1] = 0

				local pattern_identifier = color_lookup[b2] + color_lookup[b3] * 3 + color_lookup[b4] * 4 + color_lookup[b5] * 20 + color_lookup[b6] * 100

				local fg_location = texel_foreground_lookup[pattern_identifier]
				local bg_location = texel_background_lookup[pattern_identifier]

				texel_body[1] = b1
				texel_body[2] = b2
				texel_body[3] = b3
				texel_body[4] = b4
				texel_body[5] = b5
				texel_body[6] = b6

				fg = texel_body[fg_location]
				bg = texel_body[bg_location]

				char = texel_character_lookup[pattern_identifier]
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

---@param color color
function box_object:clear(color)
	pixelbox.restore(self,color)
end

---@param x integer
---@param y integer
---@param color color
function box_object:setPixel(x,y,color)
	self.data[y][x] = color
end

---@param w integer
---@param h integer
---@param color color
function box_object:resize(w, h, color)
	self.width = w*2
	self.height = h*3
	pixelbox.restore(self, color or self.background or colors.black, true)
end

---@param terminal Redirect
---@param bg? color
---@return pixelbox.box
function pixelbox.new(terminal, bg)
	---@class pixelbox.box
	local box = {}
	box.background = bg or terminal.getBackgroundColor() or colors.black
	box.term = terminal

	local w,h = terminal.getSize()
	box.width = w*2
	box.height = h*3
	box.owner = "pixelbox"
	box.clear = box_object.clear
	box.render = box_object.render
	box.resize = box_object.resize
	box.setPixel = box_object.setPixel

	pixelbox.restore(box, box.background)
	return box
end

---@param canvas parea.Canvas|hmon.Canvas|pixelbox.box
function pixelbox.own(canvas)
	canvas.clear = box_object.clear
	canvas.render = box_object.render
	canvas.resize = box_object.resize
	canvas.setPixel = box_object.setPixel
	canvas.owner = "pixelbox"
end

generate_lookups()
return pixelbox