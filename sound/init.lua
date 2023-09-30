local sound = {}

---@type Speaker[]
local channels = {peripheral.find("speaker")}
local fakeSpeaker = false

if #channels == 0 then
    if periphemu then
        periphemu.create("right", "speaker")
        channels[1] = peripheral.find("speaker")
    else
        channels[1] = {
            playAudio = function() end,
            playNote = function() end,
            playSound = function() end,
            stop = function() end,
        }
        fakeSpeaker = true
    end
end

---@type path
local path = ""

---@class note
---@field channel integer
---@field pitch number
---@field instrument instrument
---@field volume number
---@field latency number?

---@class notes
---@field timestamp number

---@class obsi.Sound
---@field duration number measured in seconds
---@field data notes[]

---@type obsi.Sound[]
local soundbuffer = {}

---@type note[]
local notebuffer = {}

---@param channel integer
---@param instrument instrument
---@param pitch number  from 0 to 24
---@param volume number? from 0 to 3
---@param latency number? in seconds
function sound.playNote(channel, instrument, pitch, volume, latency)
    volume = math.max(math.min(volume or 1, 3), 0)
    pitch = math.max(math.min(pitch, 24), 0)
    latency = latency or 0
    notebuffer[#notebuffer+1] = {pitch = pitch, channel = channel, instrument = instrument, volume = volume, latency = latency}
    table.sort(notebuffer, function (n1, n2)
        return n1.latency < n2.latency
    end)
end

function sound.isAvailable()
    return not fakeSpeaker
end

function sound.refreshChannels()
    local chans = {peripheral.find("speaker")}
    if chans ~= 0 then
        channels = chans
    end
end

function sound.getChannelCount()
    return #channels
end

function sound.isPlaying()
    return #notebuffer > 0 or #soundbuffer > 0
end

function sound.notesPlaying()
    return #notebuffer
end

-- TODO!
-- As of 9th of August, I still have no idea how to implement this.
-- As of 30th of September, I may have an idea how to implement this.
function sound.newSound(soundPath)
    soundPath = fs.combine(path, soundPath)
    if not fs.exists(soundPath) then
        error(("Sound path does not exist: %s"):format(path), 2)
    elseif fs.isDir(soundPath) then
        error(("Sound path is a directory: %s"):format(path), 2)
    end
    local fh, e = fs.open(soundPath, "r")
    if not fh then
        error(e)
    end
    fh.close()
end

---@param dt number
local function soundLoop(dt)
    for i, note in ipairs(notebuffer) do
        note.latency = note.latency - dt
        if note.latency <= 0 then
            local speaker = channels[((note.channel-1) % #channels)+1]
            speaker.playNote(note.instrument, note.volume, note.pitch)
            table.remove(notebuffer, i)
        end
    end
end

return function (gamePath)
    path = gamePath
    return sound, soundLoop
end