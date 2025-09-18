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

--- @param state ModelState
--- @param filepath_from_cwd string
--- @return ModelState
function M.with_file_expanded(state, filepath_from_cwd)
  local result_state = model_state.ModelState:new(state)
  local node_to_expand = state:getFileGraphNodeAtPathFromCwd(filepath_from_cwd)
  local children = M.expand_children(node_to_expand)

  result_state.root = state:getRoot():withNodeAtPathReplaced(filepath_from_cwd, FileGraph:new({
    filepath_from_cwd=filepath_from_cwd,
    children=children,
  }))

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
