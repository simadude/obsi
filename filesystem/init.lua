local filesystem = {}
local useGamePath = false
local gamePath = ""

---@param path string
---@return string?, string?
local function getPath(path)
	-- if useGamePath then
	-- 	local s = fs.combine(gamePath, path):reverse():sub(-#gamePath):reverse()
	-- 	if s ~= gamePath then
	-- 		return nil, ("Attempt to get outside of the game's directory: %s"):format(s)
	-- 	end
	-- end
	return useGamePath and fs.combine(gamePath, path) or path
end

---Creates a new obsi.File object. Does not necessarily create a new file. Needs to be opened manually for writing.
---@param filePath string
---@param fileMode? fileMode
---@return obsi.File?, string?
function filesystem.newFile(filePath, fileMode)
	local fp, e = getPath(filePath)
	if not fp then
		return nil, e
	end
	fileMode = fileMode or "c"

	---@class obsi.File
	local file = {}

	file.path = filePath
	file.name = fs.getName(filePath)

	---@alias fileMode "c"|"r"|"w"|"a"
	---@type fileMode
	file.mode = fileMode

	---@param mode fileMode
	function file:open(mode)
		if mode == "c" then
			return
		end
		local f, e = fs.open(self.path, mode ~= "r" and mode.."b" or mode)
		if not f then
			return false, e
		end
		self.file = f
		return true
	end

	if fileMode ~= "c" then
		local b, e = file:open(fileMode)
		if not b then
			return nil, e
		end
	end

	function file:getMode()
		return self.mode
	end

	function file:write(data, size)
		if self.file and (self.mode == "w" or self.mode == "a") then
			size = size or #data
			self.file.write(data:sub(size))
			return true
		else
			return false, "File is not opened for writing"
		end
	end

	function file:flush()
		if self.mode == "w" and self.file then
			self.file.flush()
			return true
		else
			return false, "File is not opened for writing"
		end
	end

	function file:read(count)
		if not self.file then
			local _, r = self:open("r")
			if r then
				return nil, r
			end
		elseif self.mode ~= "r" then
			return nil, "File is not opened for reading"
		end
		return count and self.file.read(count) or self.file.readAll()
	end

	function file:lines()
		if not self.file then
			local _, r = self:open("r")
			if r then
				error(r)
			end
		elseif self.mode ~= "r" then
			return nil, "File is not opened for reading"
		end
		return function ()
			return self.file.readLine(false)
		end
	end

	function file:seek(pos)
		if self.file then
			self.file.seek("set", pos)
		end
	end

	function file:tell()
		if self.file then
			return self.file.seek("cur", 0)
		end
	end

	function file:close()
		if self.file then
			self.file.close()
		end
		self.file = nil
		self.mode = "c"
	end

	return file
end

---@class obsi.FileInfo
---@field type "directory"|"file"
---@field size number
---@field modtime number
---@field createtime number
---@field readonly boolean

---@param filePath string
---@return obsi.FileInfo?
function filesystem.getInfo(filePath)
	filePath = getPath(filePath)
	local e, inf = pcall(fs.attributes, filePath)
	if not inf then
		return nil
	end
	return {
		type = (inf.isDir and "directory" or "file"),
		size = inf.size,
		modtime = inf.modified,
		createtime = inf.created,
		readonly = inf.isReadOnly
	}
end

---Returns contents of the file in a form of a string.
---If the file can't be read, then nil and an error message is returned.
---@param filePath string
---@return string|nil, nil|string
function filesystem.read(filePath)
	filePath = getPath(filePath)
	local fh, e = fs.open(filePath, "rb")
	if not fh then
		return nil, e
	end
	return fh.readAll() or ""
end

---@param filePath string
---@param data string
function filesystem.write(filePath, data)
	filePath = getPath(filePath)
	local fh, e = fs.open(filePath, "wb")
	if not fh then
		return nil, e
	end
	fh.write(data)
	fh.close()
end

---Returns an iterator, similar to `io.lines`.
---If the file can't be read, then the function errors.
---@param filePath string
---@return fun(): string|nil
function filesystem.lines(filePath)
	filePath = getPath(filePath)
	local fh, e = fs.open(filePath, "rb")
	if not fh then
		error(e)
	end
	return function ()
		return fh.readLine(false) or fh.close()
	end
end

local function init(path)
	gamePath = fs.combine(path)
	return filesystem, function() useGamePath = true end
end

return init