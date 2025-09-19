local path_utils = require("utils.path")

local M = {}

M.defaults = {
  directory = "",
  directory_expanded = "",
  file = ""
}

M.highlights = {
  directory = "Directory",
  directory_expanded = "Directory",
  file = "Title"
}

--- @param icon_name string Name of icon to get
--- @return string icon
function M.get(icon_name)
  if vim.g.tbrow_icons and vim.g.tbrow_icons[icon_name] then
    return vim.g.tbrow_icons[icon_name]
  end
  return M.defaults[icon_name]
end

function M.get_key_for_file_node(node)
  if path_utils.path_is_directory(node:absoluteFilepath()) then
    if node:isExpanded() then
      return "directory_expanded"
    else
      return "directory"
    end
  end
  return M.get_key_for_file_path(node:absoluteFilepath())
end

function M.get_key_for_file_path(filepath)
  local _ = filepath
  return "file"
end

--- Return the appropriate file icon for the file at the given path.
--- Does not support directories.
--- @param filepath string
--- @return string icon
function M.get_for_file_path(filepath)
  return M.get(M.get_key_for_file_path(filepath))
end

--- @param node FileGraph 
--- @return string icon
function M.get_for_file_node(node)
  return M.get(M.get_key_for_file_node(node))
end

function M.get_highlight(key)
  return M.highlights[key]
end

function M.get_highlight_for_file_node(node)
  return M.get_highlight(M.get_key_for_file_node(node))
end


return M
