local state = {}
local globals = {}
---@type table<string, obsi.Scene>
local scenes = {}

---@return obsi.Scene
---@param sceneName string
function state.newScene(sceneName)
	---@class obsi.Scene
	local scene = {}

	scene.variables = {}

	---@param self obsi.Scene
	---@param varName string
	---@param value any
	scene.setVariable = function (self, varName, value)
		self.variables[varName] = value
	end

	---@param self obsi.Scene
	---@param varName string
	scene.getVariable = function (self, varName)
		return self.variables[varName]
	end

	scene.objects = {}

	scenes[sceneName] = scene
	return scene
end

---@param sceneName string
---@return obsi.Scene?
function state.getScene(sceneName)
	return scenes[sceneName]
end

---@param sceneName string
---@param scene obsi.Scene?
function state.setScene(sceneName, scene)
	scenes[sceneName] = scene
end

function state.everyScene()
	return pairs(scenes)
end

---@param name string
---@param val any
function state.setGlobal(name, val)
	globals[name] = val
end

---@return any
function state.getGlobal(name)
	return globals[name]
end

state.newScene("Default")

return state