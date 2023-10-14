local nbs = {}

-- The parsing function for .nbs was made by Xella. Huge thanks to them for making it.
-- This thing is just a bit modified to work with the Obsi Game Engine.
-- The original repo can be found here: https://github.com/Xella37/NBS-Tunes-CC

function nbs.parseNBS(data)
	local nbsRaw = string.gsub(data, "\r\n", "\n")
	local seekPos = 1

	local byte = string.byte
	local lshift = bit.blshift --[[@as function]]

	local function readInteger()
		local buffer = nbsRaw:sub(seekPos, seekPos+3)
		seekPos = seekPos + 4

		if #buffer < 4 then return end

		local byte1 = byte(buffer, 1)
		local byte2 = byte(buffer, 2)
		local byte3 = byte(buffer, 3)
		local byte4 = byte(buffer, 4)

		return byte1 + lshift(byte2, 8) + lshift(byte3, 16) + lshift(byte4, 24)
	end

	local function readShort()
		local buffer = nbsRaw:sub(seekPos, seekPos+1)
		seekPos = seekPos + 2

		if #buffer < 2 then return end

		local byte1 = byte(buffer, 1)
		local byte2 = byte(buffer, 2)

		return byte1 + lshift(byte2, 8)
	end

	local function readByte()
		local buffer = nbsRaw:sub(seekPos, seekPos)
		seekPos = seekPos + 1

		return byte(buffer, 1)
	end

	local function readString()
		local length = readInteger()
		if length then
			local txt = nbsRaw:sub(seekPos, seekPos + length - 1)
			seekPos = seekPos + length
			return txt
		end
	end

	-- Metadata
	local song = {}
	song.zeros = readShort() -- new in version 1
	local legacy = song.zeros ~= 0
	local version = 0

	if legacy then
		song.length = song.zeros -- zeros don't exist in v0, so use those bytes for length
		song.zeros = nil
	else
		version = readByte()
		song.nbs_version = version
		song.vanilla_instrument_count = readByte()

		if version >= 3 then -- zeros replaced song length, but was added back in in v3
			song.length = readShort()
		end
	end
	song.layer_count = readShort() --- called height in legacy
	song.name = readString()
	song.author = readString()
	song.ogauthor = readString()
	song.desc = readString()
	song.tempo = readShort() or 1000
	seekPos = seekPos + 23 -- Sima: gotta skip some stuff
	readString()
	if version >= 4 then
		song.loop = readByte()
		song.max_loops = readByte()
		song.loop_start_tick = readShort()
	end

	-- song.tempo is 100 * the t/s, we compute the delay (or seconds per tick) to use when playing the audio
	local ticksPerSecond = song.tempo / 100
	local delay = 1 / ticksPerSecond

	local ticks = {}
	local currenttick = -1

	while true do
		-- We skip by step layers ahead
		local step = readShort()

		-- A zero step means we go to the next part (which we don't need so we just ignore that)
		if step == 0 then
			break
		end

		currenttick = currenttick + step

		-- lpos is the current layer (in the internal structure, we ignore NBS's editor layers for convenience)
		local lpos = 1
		ticks[currenttick] = {}

		local currentLayer = -1
		while true do
			-- Check how big the jump from this note to the next one is
			local jump = readShort()
			currentLayer = currentLayer + jump

			-- If its zero, we should go to the next tick
			if jump == 0 then
				break
			end

			-- But if its not, we read the instrument and note number
			local inst = readByte() + 1 -- +1 so it starts at 1
			local note = readByte()
			local velocity, panning, note_block_pitch
			if not legacy then
				if version >= 4 then -- note panning, velocity and note block fine pitch added in v4
					velocity = readByte() / 100
					panning = readByte() - 100
					note_block_pitch = readShort()
				end
			end

			-- And add them to the internal structure
			ticks[currenttick][lpos] = {
				inst = inst,
				note = note,
				velocity = velocity or 1,
				panning = panning or 0,
				fine_pitch = note_block_pitch,
				layer = currentLayer+1,
			}
			lpos = lpos + 1
		end
	end

	-- we now parse the headers
	local layers = {}
	for i = 1, song.layer_count do
		local name = readString()
		local velocity
		if version > 0 then
			readByte() -- Sima: `locked` is not useful for playing.
			velocity = readByte() / 100
			readByte() -- Sima: `panning` is also not very useful since we are planning for manual stuff.
		end

		local layer = {
			name = name,
			velocity = velocity or 1,
		}
		layers[i] = layer
	end

	for i = 0, currenttick do
		local tick = ticks[i]
		if tick then
			for j = 1, #tick do
				local sound = tick[j]
				local layerNr = sound.layer
				local layer = layers[layerNr]
				sound.velocity_layer = layer.velocity
			end
		end
	end

	-- parse custom instruments
	local customInstrumentCount = readByte() -- in one of the test turned out to be nil??
	if customInstrumentCount and customInstrumentCount ~= 0 then
		error(("Sorry, no custom instruments! Count: %s"):format(customInstrumentCount), 3)
	end

	-- now, let's convert this to Obsi readable stuff!
	---@type obsi.Audio
	local s = {
		name = song.name,
		description = song.desc,
		bpm = song.tempo*60,
		duration = -1,
		notes = {},
	}

	local currentTick = 0
	local time = 0
	local notes = {}

	local instruments = {
		"harp", --0 = Piano (Air)
		"bass", --1 = Double Bass (Wood)
		"basedrum", --2 = Bass Drum (Stone)
		"snare", --3 = Snare Drum (Sand)
		"hat", --4 = Click (Glass)
		"guitar", --5 = Guitar (Wool)
		"flute", --6 = Flute (Clay)
		"bell", --7 = Bell (Block of Gold)
		"chime", --8 = Chime (Packed Ice)
		"xylophone", --9 = Xylophone (Bone Block)
		"iron_xylophone", --10 = Iron Xylophone (Iron Block)
		"cow_bell", --11 = Cow Bell (Soul Sand)
		"didgeridoo", --12 = Didgeridoo (Pumpkin)
		"bit", --13 = Bit (Block of Emerald)
		"banjo", --14 = Banjo (Hay)
		"pling", --15 = Pling (Glowstone)
	}
	while true do
		local tick = ticks[currentTick]
		if tick then
			for j = 1, #tick do
				local sound = tick[j]
				local inst = sound.inst
				local noteVolume = sound.velocity * sound.velocity_layer

				-- I don't need octave offset, sory Xella :3
				-- This is how the thing is defined in the NBS specification anyway.
				local pitch = sound.note - 33
				if pitch > 24 then
					pitch = pitch % 12 + 12
				elseif pitch < 0 then
					pitch = pitch % 12
				end

				if inst <= 16 then
					local instrument = instruments[inst]
					notes[#notes+1] = {instrument = instrument, volume = noteVolume, pitch = pitch, speaker = 1, timing = time} ---@type note
				end
			end
		end

		local found = false
		local waitTicks = 0
		for j = currentTick+1, song.length do
			if ticks[j] then
				found = true
				waitTicks = j - currentTick
				currentTick = j
				break
			end
		end
		if not found then
			break -- stop playing
		end
		time = time + delay * waitTicks
	end
	s.duration = time
	table.sort(notes, function (note1, note2)
		return note1.timing < note2.timing
	end)
	s.notes = notes
	return s
end

return nbs