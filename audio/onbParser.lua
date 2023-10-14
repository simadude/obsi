local onb = {}

---@param data string
onb.parseONB = function (data)
	if data:sub(-1) ~= "\n" then
		data = data.."\n"
	end
	---@type string[]
	local lines = {}
	for s in data:gmatch("(.-)\n") do
		lines[#lines+1] = s
	end
	-- first we check if the first one has ONB signature
	if lines[1] ~= "ONB,Obsi NoteBlock" then
		error("File doesn't have ONB signature")
	end
	-- now let's carefully parse each line
	-- first some metadata
	local name = lines[2]
	local description = lines[3]
	local bpm = tonumber(lines[4]) or 60
	local duration = 0
	-- preparing to parse some stuff
	local columnNames = {}
	for s in (lines[5]..","):gmatch("(.-),") do
		columnNames[#columnNames+1] = s
	end
	local notes = {}
	for l = 6, #lines do
		local str = lines[l]..","
		if str:sub(1, 1) ~= "#" then
			local note = {}
			local charstart = 1
			local charend = 1
			for i = 1, #columnNames do
				charend = str:find(",", charstart)
				note[columnNames[i]] = str:sub(charstart, charend-1)
				charstart = charend+1
			end
			local notPresent = {}
			if not note.timing then
				notPresent[#notPresent+1] = "timing"
			end
			if not note.pitch then
				notPresent[#notPresent+1] = "pitch"
			end
			if not note.instrument then
				notPresent[#notPresent+1] = "instrument"
			end
			if #notPresent > 0 then
				local nP = ""
				for i, s in ipairs(notPresent) do
					nP = nP..s
					if i ~= #notPresent then
						nP = nP..", "
					end
				end
				print(#columnNames)
				error(("Fields like: {%s} are not present!"):format(nP))
			end
			note.pitch = tonumber(note.pitch)
			note.timing = tonumber(note.timing)*(60/bpm)
			duration = math.max(duration, note.timing+(60/bpm))
			note.speaker = tonumber(note.speaker) or 1
			note.volume = tonumber(note.volume) or 1
			notes[#notes+1] = note
		end
	end
	table.sort(notes, function (note1, note2)
		return note1.timing < note2.timing
	end)
	return {
		name = name,
		description = description,
		bpm = bpm,
		notes = notes,
		duration = duration
	}
end

return onb