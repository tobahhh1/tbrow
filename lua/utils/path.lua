local M = {}

--- @param s string
M.path_is_directory = function(s)
  return not not string.match(s, ".*/$")
end

M.iter_path_elements = function(s)
  return string.gmatch(s, "[^/]+/?")
end

return M
