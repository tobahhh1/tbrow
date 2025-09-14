--- @param s string
local function path_is_directory(s)
  return not not string.match(s, ".*/$")
end

return path_is_directory
