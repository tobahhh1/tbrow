local path_utils = require("utils.path")

--- @class FileGraph
--- @field absolute_filepath string
--- @field children table<string, FileGraph> | nil
local prototype = {
  absolute_filepath = "",
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

function prototype:absoluteFilepath()
  return self.absolute_filepath
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

--- @param absolute_filepath string
--- @param node_replacement FileGraph
--- @return FileGraph
function prototype:withNodeAtPathReplaced(absolute_filepath, node_replacement)
  if absolute_filepath == self.absolute_filepath then
    return node_replacement
  end

  local node_to_replace_root_path, node_to_replace_filename = path_utils.split_root_and_filename(
    path_utils.without_prefix(absolute_filepath, self.absolute_filepath))

  local root_replacement = prototype:new({
      absolute_filepath = self.absolute_filepath,
      children = shallow_copy(self.children)
  })

  local curr_node = root_replacement
  for path_el in path_utils.iter_path_elements(node_to_replace_root_path) do
    if path_el ~= "./" and path_el ~= "." then
      local old_child = curr_node.children[path_el]
      local new_child = prototype:new({
        absolute_filepath = old_child.absolute_filepath,
        children = shallow_copy(old_child.children)
      })
      curr_node.children[path_el] = new_child
      curr_node = new_child
      if curr_node == nil then
        error("Path " .. absolute_filepath .. " is not currently indexed")
      end
    end
  end
  curr_node.children[node_to_replace_filename] = node_replacement

  return root_replacement
end
return prototype
