---@class obsi.time
local time = {}
local initTime = os.clock()

function time.getTime()
	return os.clock() - initTime
end

return time