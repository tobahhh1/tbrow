local path_utils = require("utils.path")

local M = {}

--- @class ModelState
--- @field root FileGraph
local prototype = {}

--- @param o ModelState
--- @return ModelState
function prototype:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function prototype:getRoot()
  return self.root
end


--- @param path_from_cwd string
function prototype:getFileGraphNodeAtPathFromCwd(path_from_cwd)
  local curr_node = self.root
  for path_el in path_utils.iter_path_elements(path_from_cwd) do
    -- same directory
    if path_el ~= "." and path_el ~= "./" then
      curr_node = curr_node.children[path_el]
      if curr_node == nil then
        error("Path " .. " not indexed in current file tree, perhaps there are directories you need to expand?")
      end
    end
  end
  return curr_node
end

M.ModelState = prototype


return M
