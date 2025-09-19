local M = {}

--- @param s string
M.path_is_directory = function(s)
  --- if empty string, it's a directory
  --- because it msut be referring to the root! 
  return #s == 0 or not not string.match(s, ".*/$")
end

M.iter_path_elements = function(s)
  return string.gmatch(s, "[^/]+/?")
end

M.split_root_and_filename = function(s)
  local filename_ind = string.find(s, "[^/]*/?$")
  if filename_ind == nil then
    error("Invalid path " .. s)
  end
  return string.sub(s, 1, filename_ind - 1), string.sub(s, filename_ind)
end

function M.without_prefix(s, prefix)
    if s:sub(1, #prefix) == prefix then
        return s:sub(#prefix + 1)
    else
        error(s .. " does not start with " .. prefix)
    end
end


return M
