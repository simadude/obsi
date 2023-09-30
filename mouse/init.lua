local mouse = {}
local lastx, lasty, lastc = 0, 0, 0
local isAvailable = false

mouse.getLastPosition = function ()
    return lastx, lasty
end

mouse.getLastButton = function ()
    return lastc
end

mouse.isAvailable = function ()
    return isAvailable
end

local function setMouse(x, y, c)
    lastx, lasty, lastc = x, y, c
end

return function (exists)
    isAvailable = exists
    return mouse, setMouse
end