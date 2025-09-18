local path_utils = require("utils.path")

local M = {}

M.defaults = {
  directory = "",
  directory_expanded = "",
  file = ""
}

--- @param icon_name string Name of icon to get
--- @return string icon
function M.get(icon_name)
  if vim.g.tbrow_icons and vim.g.tbrow_icons[icon_name] then
    return vim.g.tbrow_icons[icon_name]
  end
  return M.defaults[icon_name]
end

--- Return the appropriate file icon for the file at the given path.
--- Does not support directories.
--- @param filepath string
--- @return string icon
function M.get_for_file_path(filepath)
  local _ = filepath
  return M.get("file")
end

--- @param node FileGraph 
--- @return string icon
function M.get_for_file_node(node)
  if path_utils.path_is_directory(node:getFilepathFromCwd()) then
    if node:isExpanded() then
      return M.get("directory_expanded")
    else
      return M.get("directory")
    end
  end
  return M.get_for_file_path(node:getFilepathFromCwd())
end


return M
