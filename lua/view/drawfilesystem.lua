

local default_indent_string = "  "
local function get_indent_string()
  if vim.g.tbrow_indent_string ~= nil then
    return vim.g.tbrow_indent_string
  end
  return default_indent_string
end

--- @param path string
local function get_filename(path)
  return string.match(path, "[^/]*/?$")
end

--- Draw the tbrow window representing the file tree at the given buffer 
--- @param root FileGraph Root node of file graph to draw
--- @param metadata table<string, FileMetadata> Map of file name to file metadata
--- @param bufnr integer Buffer number to draw to
local function draw_filesystem(root, metadata, bufnr)
  local lines = {}
  local stack = {
    {
      node = root,
      indent_level = 0
    }
  }
  while #stack > 0 do
    local current = stack[#stack]

    local current_indent_string = ""
    for _ = 1, current.indent_level do
      current_indent_string = current_indent_string .. get_indent_string()
    end

    table.insert(lines, current_indent_string .. get_filename(current.node.absolute_filepath))
    if current.children then
      for _, child in ipairs(current.node.children) do
        table.insert({
          node = child,
          indent_level = current.indent_level + 1
        }, child)
      end
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return draw_filesystem
