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
  local cmd = {"ls", "-aF"}
  if #node.filepath_from_cwd ~= 0 then
    table.insert(cmd, node.filepath_from_cwd)
  end
  local ls_output = vim.system(cmd, { text = true}):wait()
  if ls_output.code ~= 0 then
    error("Cannot expand " .. node.filepath_from_cwd .. ": ls failed; does the file exist?")
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

--- @param state ModelState
--- @param filepath_from_cwd string
--- @return ModelState
function M.with_file_expanded(state, filepath_from_cwd)

  local result_state = model_state.ModelState:new(state)

  local path_to_first_not_expanded_node = ""
  local first_path_el_not_expanded = ""
  local iterator = path_utils.iter_path_elements(filepath_from_cwd)
  local curr_node = state:getRoot()
  for path_el in iterator do
    path_to_first_not_expanded_node = path_to_first_not_expanded_node .. path_el
    print("Loop " .. path_to_first_not_expanded_node)
    if not curr_node:isExpanded() then
      first_path_el_not_expanded = path_el
      break
    end
    curr_node = curr_node.children[path_el]
    if curr_node == nil then
      error("File does not exist")
    end
  end

  print("Need to expand " .. path_to_first_not_expanded_node)
  print("Replacing " .. curr_node.filepath_from_cwd)

  local expanded_replacement_node = FileGraph:new(curr_node)
  expanded_replacement_node.children = M.expand_children(curr_node)
  print(#expanded_replacement_node.children)

  -- already took path_el out of the iterator, so we need to iterate this one manually.
  curr_node = expanded_replacement_node.children[first_path_el_not_expanded]

  for path_el in iterator do
    local child = curr_node.children[path_el]
    child.children = M.expand_children(child)
    curr_node = child
  end

  result_state.root = state:getRoot():withNodeAtPathReplaced(path_to_first_not_expanded_node, expanded_replacement_node)

  return result_state
end

function M.with_file_collapsed(state, filepath_from_cwd)
  local result_state = model_state.ModelState:new(state)
  result_state.root = state:getRoot():withNodeAtPathReplaced(filepath_from_cwd, FileGraph:new({
    filepath_from_cwd=filepath_from_cwd,
    children=nil
  }))
  return result_state
end

return M
