local args = {...}
local gamePath = args[1]
if not gamePath then
	printError("Obsi error: No path specified!")
	printError("Usage: obsi <path>")
	return
end
gamePath = fs.combine(shell.dir(), gamePath)
if not fs.exists(gamePath) then
	printError("Obsi error: Path does not exist!")
	printError(("Path being: %s"):format(gamePath))
	printError("Please make sure that your path is correct!")
	return
elseif not fs.isDir(gamePath) then
	printError("Obsi error: Path is not a folder!")
	printError(("Path being: %s"):format(gamePath))
	printError("Please make sure that your path is correct!")
	return
end
---@class obsi
obsi = {}

---@class obsi.Config
local config = {
	maxfps = 20,
	mintps = 60,
	multiUpdate = true,
	renderingAPI = "parea"
}

---@type fun(tab: obsi.Config)
obsi.config = nil

local function catch(err)
	obsi.graphics.clearPalette()
	term.setBackgroundColor(colors.black)
	term.clear()
	term.setCursorPos(1, 1)
	printError(debug.traceback(err, 2))
	-- if obsi.debugger then
	-- 	obsi.debugger.print(debug.traceback(err, 2))
	-- end
end

local r = require "cc.require"
local env = setmetatable({obsi = obsi}, { __index = _G })
env.require, env.package = r.make(env, gamePath)
if fs.exists(fs.combine(gamePath, "config.lua")) then
	local chunk, err = loadfile(fs.combine(gamePath, "config.lua"), "bt", env)
	if not chunk then
		printError(("obsi: config.lua file is found but can't be executed!"))
		printError(err)
		return
	end
	xpcall(chunk, catch)
	if obsi.config then
		obsi.config(config)
	end
	-- if config.maxfps > config.mintps then
	--	config.maxfps = config.mintps
	-- end
end

-- obsi.debugger = peripheral.find("debugger") or (periphemu and periphemu.create("right", "debugger") and peripheral.find("debugger")) or {print = function (...) end}
-- _G.debugger = _G.debugger or obsi.debugger
---@type obsi.Canvas|parea.Canvas
local canvas
---@type Window
local winh
---@type fun(), fun(), fun(), fun()
local soundLoop, mouseDown, mouseMove, mouseUp
local emptyFunc = function(...) end
---@type fun()
local fsInit
obsi.filesystem, fsInit = require("filesystem.init")(gamePath)
obsi.system = require("system")
---@type obsi.graphics, obsi.Canvas|parea.Canvas, Window
obsi.graphics, canvas, winh = require("graphics")(obsi.filesystem, config.renderingAPI)
obsi.time = require("time")
obsi.keyboard = require("keyboard")
obsi.mouse, mouseDown, mouseUp, mouseMove = require("mouse")()
obsi.audio, soundLoop = require("audio")(obsi.filesystem)
obsi.state = require("state")
obsi.debug = false
obsi.version = "1.5.1"

local chunk, err = loadfile(fs.combine(gamePath, "main.lua"), "bt", env)
if not chunk then
	printError(("obsi: %s not found!"):format(fs.combine(gamePath, "main.lua")))
	printError(err)
	return
end

obsi.load = emptyFunc
---@type fun(dt: number)
obsi.update = emptyFunc
---@type fun(dt: number)
obsi.draw = emptyFunc
---@type fun(x: number, y: number, button: integer)
obsi.mousePressed = emptyFunc
---@type fun(x: number, y: number, button: integer)
obsi.mouseReleased = emptyFunc
---@type fun(x: number, y: number)
obsi.mouseMoved = emptyFunc
---@type fun(key: integer)
obsi.keyPressed = emptyFunc
---@type fun(key: integer)
obsi.keyReleased = emptyFunc
---@type fun(wind: Window)
obsi.windowFlush = emptyFunc -- sends a window object as a first argument, which you can mutate if you wish.
---@type fun(w: integer, h: integer)
obsi.resize = emptyFunc	-- sends width and height of the window in characters, not pixels. 
---@type fun(eventData: table)
obsi.onEvent = emptyFunc -- for any events that aren't caught! Runs last so that you won't mutate it.
---@type fun()
obsi.quit = emptyFunc -- called when Obsi recieves "terminate" event.

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

fsInit() -- use game's path

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
		obsi.graphics.setCanvas()
		soundLoop(dt)
		if obsi.debug then
			local bg, fg = obsi.graphics.bgColor, obsi.graphics.fgColor
			obsi.graphics.bgColor, obsi.graphics.fgColor = colors.black, colors.white
			obsi.graphics.write("Obsi "..obsi.version, 1, 1)
			obsi.graphics.write(obsi.system.getHost(), 1, 2)
			obsi.graphics.write(("rendering: %s [%sx%s]"):format(obsi.graphics.getRenderer(), obsi.graphics.getPixelSize()), 1, 3)
			obsi.graphics.write(("%.2f fps"):format(1/dt), 1, 4)
			obsi.graphics.write(("%0.2fms update"):format(updateTime*1000), 1, 5)
			obsi.graphics.write(("%0.2fms draw"):format(drawTime*1000), 1, 6)
			obsi.graphics.write(("%0.2fms frame"):format(frameTime*1000), 1, 7)
			obsi.graphics.bgColor, obsi.graphics.fgColor = bg, fg
		end
		-- obsi.debugger.print(("%0.2fms frame [%sx%s]"):format(frameTime*1000, obsi.graphics.getPixelSize()))
		obsi.graphics.flushAll()
		obsi.windowFlush(winh)
		obsi.graphics.show()
		frameTime = clock() - startTime
		repeat
			sleepRaw((1/config.maxfps)/20)
		until (clock()-t >= 1/config.maxfps)
		obsi.graphics.clear()
		obsi.graphics.bgColor, obsi.graphics.fgColor = colors.black, colors.white
		obsi.graphics.resetOrigin()
		dt = clock()-t
		t = clock()
	end
end

local function eventLoop()
	while true do
		local eventData = {os.pullEventRaw()}
		if eventData[1] == "mouse_click" then
			mouseDown(eventData[3], eventData[4], eventData[2])
			obsi.mousePressed(eventData[3], eventData[4], eventData[2])
		elseif eventData[1] == "mouse_up" then
			mouseUp(eventData[3], eventData[4], eventData[2])
			obsi.mouseReleased(eventData[3], eventData[4], eventData[2])
		elseif eventData[1] == "mouse_move" then -- apparently the second index is only there for compatibility? Alright.
			mouseMove(eventData[3], eventData[4])
			obsi.mouseMoved(eventData[3], eventData[4])
		elseif eventData[1] == "mouse_drag" then
			mouseMove(eventData[3], eventData[4])
			obsi.mouseMoved(eventData[3], eventData[4])
		elseif eventData[1] == "term_resize" then
			local w, h = term.getSize()
			winh.reposition(1, 1, w, h)
			canvas:resize(w, h)
			obsi.graphics.pixelWidth, obsi.graphics.pixelHeight = canvas.width, canvas.height
			obsi.graphics.width, obsi.graphics.height = w, h
			obsi.resize(w, h)
		elseif eventData[1] == "key" and not eventData[3] then
			obsi.keyboard.keys[keys.getName(eventData[2])] = true
			obsi.keyboard.scancodes[eventData[2]] = true
			obsi.keyPressed(eventData[2])

			-- --the code below is only for testing!

			-- if eventData[2] == keys.l then
			-- 	local rentab = {
			-- 		["pixelbox"] = "parea",
			-- 		["parea"] = "hmon",
			-- 		["hmon"] = "pixelbox",
			-- 	}
			-- 	obsi.graphics.setRenderer(rentab[obsi.graphics.getRenderer()] or "parea")
			-- elseif eventData[2] == keys.p then
			-- 	obsi.debug = not obsi.debug
			-- end
		elseif eventData[1] == "key_up" then
			obsi.keyboard.keys[keys.getName(eventData[2])] = false
			obsi.keyboard.scancodes[eventData[2]] = false
			obsi.keyReleased(eventData[2])
		elseif eventData[1] == "terminate" then
			obsi.quit()
			obsi.graphics.clearPalette()
			term.setBackgroundColor(colors.black)
			term.clear()
			term.setCursorPos(1, 1)
			return
		end
		obsi.onEvent(eventData)
	end
end

local s = xpcall(chunk, catch) -- execute the main.lua
if not s then
	return
end
parallel.waitForAny(function() xpcall(gameLoop, catch) end, function() xpcall(eventLoop, catch) end)