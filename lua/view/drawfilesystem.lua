local renderer = require("view/writetobuf")
local state = require("view/state")

local default_indent_string = "  "
local function get_indent_string()
  if vim.g.tbrow_indent_string ~= nil then
    return vim.g.tbrow_indent_string
  end
  return default_indent_string
end

--- Return just the name of the file, with any directories removed.
--- @param full_path string
local function get_filename_without_directories(full_path)
  return string.match(full_path, "[^/]*/?$")
end

--- Draw the tbrow window representing the file tree at the given buffer 
--- @param prev_state ViewState | nil Previous state the view was in; or nil to draw from scratch.
--- @param model_state ModelState Root node of file graph to draw
--- @param bufnr integer Buffer number to draw to
--- @return ViewState
local function draw_filesystem(prev_state, model_state, bufnr)
  local _
  _ = prev_state

  local lines = {}
  local line_num = 1
  --- @type table<integer, string>
  local line_num_to_path_from_cwd = {}
  local root = model_state:getRoot()
  local stack = {
    {
      node = root,
      indent_level = 0
    }
  }
  while #stack > 0 do
    local current = stack[#stack]
    table.remove(stack, #stack)

    local current_indent_string = ""
    for _ = 1, current.indent_level do
      current_indent_string = current_indent_string .. get_indent_string()
    end

    local filename = get_filename_without_directories(current.node:getFilepathFromCwd())
    table.insert(lines, current_indent_string .. filename)
    line_num_to_path_from_cwd[line_num] = current.node:getFilepathFromCwd()
    line_num = line_num + 1

    if current.node:isExpanded() then
      for _, child in pairs(current.node:getChildren()) do
        table.insert(stack, {
          node = child,
          indent_level = current.indent_level + 1
        })
      end
    end
  end
  renderer.write_to_buf(lines, bufnr)
  return state.ViewState:new({
    line_num_to_path_from_cwd = line_num_to_path_from_cwd
  })
end

return draw_filesystem
