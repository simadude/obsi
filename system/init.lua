local system = {}
local isAdvanced
local isEmulated = _HOST:lower():match("minecraft") and true or false
local host = _HOST:match("%(.-%)"):sub(2, -2)
local ver = _HOST:sub(15, 21)
do
	local programs = shell.programs()
	for i = 1, #programs do
		if programs[i] == "multishell" then
			isAdvanced = true
		end
	end
end

system.isAdvanced = function ()
	return isAdvanced
end

system.isEmulated = function ()
	return isEmulated
end

system.getHost = function ()
	return host
end

system.getVersion = function ()
	return ver
end

return system