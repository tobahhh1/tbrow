--- @class FileGraph
--- @field absolute_filepath string
--- @field children FileGraph[] | nil
--- @field parent FileGraph | nil
local prototype = {
  absolute_filepath = "",
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
