local renderer = require("view.writetobuf")
local state = require("view.state")
local icons = require("view.icons")

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

local function repeat_indent(indent_level)
  local indent_string = ""
  for _ = 1, indent_level do
    indent_string = indent_string .. get_indent_string()
  end
  return indent_string
end

--- @param node FileGraph
local function create_line_to_render(indent_level, node)
  local repeated_indent = repeat_indent(indent_level)
  local icon = icons.get_for_file_node(node)
  local filename = get_filename_without_directories(node:getFilepathFromCwd())
  return repeated_indent .. icon .. " " .. filename
end

local function sorted_keys(table)
  local result = {}
  for name, _ in pairs(table) do
    table.insert(result, name)
  end
  table.sort(result)
  return result
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
  local stack = {
    {
      node = model_state:getRoot(),
      indent_level = 0
    }
  }
  while #stack > 0 do
    local current = stack[#stack]
    table.remove(stack, #stack)

    table.insert(lines, create_line_to_render(current.indent_level, current.node))
    line_num_to_path_from_cwd[line_num] = current.node:getFilepathFromCwd()
    line_num = line_num + 1

    if current.node:isExpanded() then
      local children = current.node:getChildren()
      for _, name in ipairs(sorted_keys(children)) do
        local child = children[name]
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
