--- @class FileMetadata
--- @field diagnostic_level vim.diagnostic.Severity|nil
--- @field git_statuses GitStatus[]
local prototype = {
  diagnostic_level = nil,
  git_statuses = {},
}

--- @param o FileMetadata 
--- @return FileMetadata
function prototype:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

return prototype
