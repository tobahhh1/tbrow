local FileGraph = require("model.filegraph")
local model_state = require("model.state")
local path_utils = require("utils.path")

local M = {}

--- Return a copy of node where children contains
--- all items inside the directory node refers to.
--- @param node FileGraph
function M.expand_children(node)
  if not path_utils.path_is_directory(node.filepath_from_cwd) then
    error("Cannot expand " .. node.filepath_from_cwd .. ": is not a directory")
  end
  local ls_output = vim.system({"ls", "-aF", node.filepath_from_cwd}, { text = true}):wait()
  if ls_output.code ~= 0 then
    error("Cannot expand " .. node.filepath_from_cwd .. ": ls failed (unicorn!!)")
  end
  local children = {}
  for _, child_filename in ipairs(vim.fn.split(ls_output.stdout, "\n")) do
    if child_filename ~= "./" and child_filename ~= "../"  then
      children[child_filename] = FileGraph:new({
        filepath_from_cwd = node.filepath_from_cwd .. child_filename,
        children = nil,
      })
    end
  end
  return children
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
local function with_node_at_path_repalced(root, filepath_from_cwd, node_replacement)
  local node_to_replace_root_path, node_to_replace_filename = path_utils.split_root_and_filename(filepath_from_cwd)
  if node_to_replace_root_path == "" then
    -- Replacing the root
    return node_replacement
  end

  local root_replacement = FileGraph:new({
      filepath_from_cwd = root.filepath_from_cwd,
      children = shallow_copy(root.children)
  })

  local curr_node = root_replacement
  for path_el in path_utils.iter_path_elements(node_to_replace_root_path) do
    if path_el ~= "./" and path_el ~= "." then
      local old_child = curr_node.children[path_el]
      local new_child = FileGraph:new({
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

--- @param state ModelState
--- @param filepath_from_cwd string
--- @return ModelState
function M.with_file_expanded(state, filepath_from_cwd)
  local result_state = model_state.ModelState:new(state)
  local node_to_expand = state:getFileGraphNodeAtPathFromCwd(filepath_from_cwd)
  local children = M.expand_children(node_to_expand)

  result_state.root = with_node_at_path_repalced(state:getRoot(), filepath_from_cwd, FileGraph:new({
    filepath_from_cwd=filepath_from_cwd,
    children=children,
  }))

  return result_state
end

function M.with_file_collapsed(state, filepath_from_cwd)
  local result_state = model_state.ModelState:new(state)
  result_state.root = with_node_at_path_repalced(state:getRoot(), filepath_from_cwd, FileGraph:new({
    filepath_from_cwd=filepath_from_cwd,
    children=nil
  }))
  return result_state
end

return M
