local path = arg[1]
if not path then
	printError("Obsi error: No path specified!")
	printError("Usage: obsi <path>")
	return
end
path = fs.combine(shell.dir(), path)
if not fs.exists(path) then
	printError("Obsi error: Path does not exist!")
	printError(("Path being: %s"):format(path))
	printError("Please make sure that your path is correct!")
	return
elseif not fs.isDir(path) then
	printError("Obsi error: Path is not a folder!")
	printError(("Path being: %s"):format(path))
	printError("Please make sure that your path is correct!")
	return
end
---@class obsi
obsi = {}
---@type function
obsi.config = nil
local config = {
	maxfps = 20,
	mintps = 60,
	multiUpdate = true,
	renderingAPI = "parea"
}

local r = require "cc.require"
local env = setmetatable({obsi = obsi}, { __index = _G })
env.require, env.package = r.make(env, path)
if fs.exists(fs.combine(path, "config.lua")) then
	local chunk, err = loadfile(fs.combine(path, "config.lua"), "bt", env)
	if not chunk then
		printError(("obsi: config.lua file is found but can't be run!"))
		printError(err)
		return
	end
	chunk()
	if obsi.config then
		obsi.config(config)
	end
	-- if config.maxfps > config.mintps then
	--	config.maxfps = config.mintps
	-- end
end
---@type parea.Canvas|pixelbox.box
local canvas
---@type Window
local winh
local pixelbox
local soundLoop
obsi.graphics, canvas, winh, pixelbox = require("graphics")(path, config.renderingAPI)
obsi.time = require("time")
obsi.keyboard = require("keyboard")
obsi.system = require("system")
obsi.mouse = require("mouse")(obsi.system.isAdvanced())
obsi.audio, soundLoop = require("audio")(path)
local emptyFunc = function(...) end
obsi.debug = false
obsi.version = "1.1.0"
-- obsi.debugger = peripheral.find("debugger") or (periphemu and periphemu.create("right", "debugger") and peripheral.find("debugger"))

local chunk, err = loadfile(fs.combine(path, "main.lua"), "bt", env)
if not chunk then
	printError(("obsi: %s not found!"):format(fs.combine(path, "main.lua")))
	printError(err)
	return
end
chunk()

obsi.load = obsi.load or emptyFunc
obsi.update = obsi.update or emptyFunc
obsi.draw = obsi.draw or emptyFunc
obsi.mousePressed = obsi.mousePressed or emptyFunc
obsi.keyPressed = obsi.keyPressed or emptyFunc
obsi.keyReleased = obsi.keyReleased or emptyFunc
obsi.quit = obsi.quit or emptyFunc

local function clock()
	return periphemu and os.epoch(("nano")--[[@as "local"]])/10^9 or os.clock()
end

---@param time number
local function sleepRaw(time)
	local timerID = os.startTimer(time)
	while true do
		local _, tID = os.pullEventRaw("timer")
		if tID == timerID then
			break
		end
	end
end

local t = clock()
local dt = 1/config.maxfps

local drawTime = t
local updateTime = t
local frameTime = t

local function gameLoop()
	obsi.load()
	while true do
		local startTime = clock()
		if config.multiUpdate then
			local updated = false
			for _ = 1, dt/(1/config.mintps) do
				obsi.update(1/config.mintps)
				updated = true
			end
			if not updated then
				obsi.update(dt)
			end
		else
			obsi.update(dt)
		end
		updateTime = clock() - startTime
		startTime = clock()
		obsi.draw(dt)
		drawTime = clock() - startTime
		soundLoop(dt)
		if obsi.debug then
			local bg, fg = obsi.graphics.bgColor, obsi.graphics.fgColor
			obsi.graphics.bgColor, obsi.graphics.fgColor = colors.black, colors.white
			obsi.graphics.write(obsi.system.getHost(), 2, 1)
			obsi.graphics.write(("rendering: %s [%sx%s]"):format(config.renderingAPI, obsi.graphics.getPixelSize()), 2, 2)
			obsi.graphics.write(("%.2f fps"):format(1/dt), 2, 3)
			obsi.graphics.write(("%0.2fms update"):format(updateTime*1000), 2, 4)
			obsi.graphics.write(("%0.2fms draw"):format(drawTime*1000), 2, 5)
			obsi.graphics.write(("%0.2fms frame"):format(frameTime*1000), 2, 6)
			obsi.graphics.bgColor, obsi.graphics.fgColor = bg, fg
		end
		obsi.graphics.flushAll()
		obsi.graphics.show()
		obsi.graphics.clear()
		obsi.graphics.bgColor, obsi.graphics.fgColor = colors.black, colors.white
		obsi.graphics.resetOrigin()
		frameTime = clock() - startTime
		repeat
			sleepRaw((1/config.maxfps)/20)
		until (clock()-t >= 1/config.maxfps)
		dt = clock()-t
		t = clock()
	end
end

local function eventLoop()
	while true do
		local eventData = {os.pullEventRaw()}
		if eventData[1] == "mouse_click" then
			obsi.mousePressed(eventData[3], eventData[4], eventData[2])
		elseif eventData[1] == "term_resize" then
			local w, h = term.getSize()
			winh.reposition(1, 1, w, h)
			if config.renderingAPI == "parea" or config.renderingAPI == "hmon" then
				canvas:resize(w, h)
			else
				-- bruh pixelbox
				pixelbox.RESIZE(canvas, w, h)
			end
			obsi.graphics.pixelWidth, obsi.graphics.pixelHeight = canvas.width, canvas.height
			obsi.graphics.width, obsi.graphics.height = w, h
		elseif eventData[1] == "key" and not eventData[3] then
			obsi.keyboard.keys[keys.getName(eventData[2])] = true
			obsi.keyboard.scancodes[eventData[2]] = true
			obsi.keyPressed(eventData[2])
		elseif eventData[1] == "key_up" then
			obsi.keyboard.keys[keys.getName(eventData[2])] = false
			obsi.keyboard.scancodes[eventData[2]] = false
			obsi.keyReleased(eventData[2])
		elseif eventData[1] == "terminate" then
			obsi.quit()
			return
		end
	end
end

parallel.waitForAny(gameLoop, eventLoop)
term.clear()
term.setCursorPos(1, 1)