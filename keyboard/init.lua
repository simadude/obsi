local keyboard = {}
keyboard.keys = {}
keyboard.scancodes = {}

---@param key string
---@return boolean
function keyboard.isDown(key)
    return keyboard.keys[key] or false
end

---@param scancode integer
---@return boolean
function keyboard.isScancodeDown(scancode)
    return keyboard.scancodes[scancode] or false
end

return keyboard