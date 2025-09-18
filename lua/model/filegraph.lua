local path_utils = require("utils.path")

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

local function shallow_copy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = v
  end
  return copy
end

--- @param filepath_from_cwd string
--- @param node_replacement FileGraph
--- @return FileGraph
function prototype:withNodeAtPathReplaced(filepath_from_cwd, node_replacement)
  local node_to_replace_root_path, node_to_replace_filename = path_utils.split_root_and_filename(filepath_from_cwd)
  if node_to_replace_root_path == "" then
    -- Replacing the root
    return node_replacement
  end

  local root_replacement = prototype:new({
      filepath_from_cwd = self.filepath_from_cwd,
      children = shallow_copy(self.children)
  })

  local curr_node = root_replacement
  for path_el in path_utils.iter_path_elements(node_to_replace_root_path) do
    if path_el ~= "./" and path_el ~= "." then
      local old_child = curr_node.children[path_el]
      local new_child = prototype:new({
        filepath_from_cwd = old_child.filepath_from_cwd,
        children = shallow_copy(old_child.children)
      })
      curr_node.children[path_el] = new_child
      curr_node = new_child
      if curr_node == nil then
        error("Path " .. filepath_from_cwd .. " is not currently indexed")
      end
    end
  end
  curr_node.children[node_to_replace_filename] = node_replacement

  return root_replacement
end
return prototype
