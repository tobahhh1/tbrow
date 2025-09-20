local FileGraph = require("model.filegraph")
local model_state = require("model.state")
local path_utils = require("utils.path")

local M = {}

--- Return a copy of node where children contains
--- all items inside the directory node refers to.
--- @param node FileGraph
function M.expand_children(node)
  if not path_utils.path_is_directory(node.absolute_filepath) then
    error("Cannot expand " .. node.absolute_filepath .. ": is not a directory")
  end
  local cmd = {"ls", "-aF"}
  if #node.absolute_filepath ~= 0 then
    table.insert(cmd, node.absolute_filepath)
  end
  local ls_output = vim.system(cmd, { text = true}):wait()
  if ls_output.code ~= 0 then
    error("Cannot expand " .. node.absolute_filepath .. ": ls failed; does the file exist?")
  end
  local children = {}
  for _, child_filename in ipairs(vim.fn.split(ls_output.stdout, "\n")) do
    if child_filename ~= "./" and child_filename ~= "../"  then
      children[child_filename] = FileGraph:new({
        absolute_filepath = node.absolute_filepath .. child_filename,
        children = nil,
      })
    end
  end
  return children
end

--- @param root FileGraph
function M.refreshed(root)
  local new_root = FileGraph:new({
    absolute_filepath = root.absolute_filepath,
  })
  local stack = {
    {
      old_node = root,
      new_node = new_root
    }
  }
  while #stack > 0 do
    local curr = table.remove(stack, #stack)
    local old_node = curr.old_node
    local new_node = curr.new_node
    if old_node:isExpanded() then
      new_node.children = M.expand_children(old_node)
      for filename, old_child in pairs(old_node:getChildren()) do
        -- don't add nodes that don't exist anymore
        if new_node.children[filename] then
          table.insert(stack, {
            old_node = old_child,
            new_node = new_node.children[filename]
          })
        end
      end
    end
  end
  return new_root
end

function M.with_root_refreshed(state)
  local new_state = model_state.ModelState:new(state)
  new_state.root = M.refreshed(state:getRoot())
  return new_state
end

--- @param state ModelState
--- @param absolute_filepath string
--- @return ModelState
function M.with_file_expanded(state, absolute_filepath)

  local result_state = model_state.ModelState:new(state)

  local curr_node = state:getRoot()
  local path_to_first_not_expanded_node = state:getRoot():absoluteFilepath()
  local iterator = path_utils.iter_path_elements(
    path_utils.without_prefix(absolute_filepath, curr_node:absoluteFilepath())
  )
  while curr_node:isExpanded() do
    local next_child_path = iterator()
    if next_child_path == nil then
      return state
    end
    curr_node = curr_node:getChildren()[next_child_path]
    path_to_first_not_expanded_node = path_to_first_not_expanded_node .. next_child_path
  end

  local expanded_replacement_node = FileGraph:new(curr_node)
  expanded_replacement_node.children = M.expand_children(expanded_replacement_node)
  curr_node = expanded_replacement_node

  for path_el in iterator do
    curr_node = curr_node.children[path_el]
    curr_node.children = M.expand_children(curr_node)
  end

  result_state.root = state:getRoot():withNodeAtPathReplaced(path_to_first_not_expanded_node, expanded_replacement_node)

  return result_state
end

function M.with_file_collapsed(state, absolute_filepath)
  local result_state = model_state.ModelState:new(state)
  result_state.root = state:getRoot():withNodeAtPathReplaced(absolute_filepath, FileGraph:new({
    absolute_filepath=absolute_filepath,
    children=nil
  }))
  return result_state
end

return M
