local path_utils = require("utils.path")
local diagnostics = require("model.diagnostic")

local M = {}

--- @class ModelState
--- @field root FileGraph
--- @field diagnostic_store DiagnosticStore
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


--- @param absolute_filepath string
function prototype:getFileGraphNodeAtAbsoluteFilepath(absolute_filepath)
  local curr_node = self.root
  for path_el in path_utils.iter_path_elements(
    path_utils.without_prefix(absolute_filepath, self.root.absolute_filepath)
  ) do
    -- same directory
    if path_el ~= "." and path_el ~= "./" then
      curr_node = curr_node.children[path_el]
      if curr_node == nil then
        return curr_node
      end
    end
  end
  return curr_node
end

function prototype:withDiagnosticsRefreshed()
  return prototype:new({
    root = self.root,
    diagnostic_store = diagnostics.DiagnosticStore:new({
      max_diag_severity_by_file_lu = diagnostics.get_max_diag_severity_by_file_lu()
    })
  })
end

M.ModelState = prototype

return M
