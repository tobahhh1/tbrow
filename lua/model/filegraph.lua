--- @class FileGraph
--- @field name string
--- @field isDirectory boolean
--- @field children FileGraph[] | nil
--- @field parent FileGraph | nil
local prototype = {
  name = "",
  isDirectory = false,
  children = {},
  parent = nil,
}

--- @param o FileGraph
--- @return FileGraph
function prototype:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

return prototype
