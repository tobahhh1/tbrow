--- @class FileGraph
--- @field name string
--- @field isDirectory boolean
--- @field children FileGraph[]
--- @field parent FileGraph | nil
--- @field metadata FileMetadata
local prototype = {
  name = "",
  isDirectory = false,
  children = {},
  parent = nil,
  metadata = {
    git_statuses = {}
  }
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
