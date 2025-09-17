--- @class FileGraph
--- @field filepath_from_cwd string
--- @field children table<string, FileGraph> | nil
local prototype = {
  filepath_from_cwd = "",
  children = nil,
}

--- @param o FileGraph
--- @return FileGraph
function prototype:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return table<string, FileGraph>
function prototype:getChildren()
  if self.children == nil then
    error("Cannot access children of file: node is not expanded")
  else
    return self.children
  end
end

function prototype:getFilepathFromCwd()
  return self.filepath_from_cwd
end

function prototype:isExpanded()
  return self.children ~= nil
end

return prototype
