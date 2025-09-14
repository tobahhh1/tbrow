local FileGraph = require("model/filegraph")
local path_is_directory = require("utils/pathisdirectory")

--- @param s string
local function iter_lines(s)
  return string.gmatch(s, ".*$")
end


--- @alias PopulateChildrenFn fun(node: FileGraph): FileGraph

--- Return a copy of node where children contains
--- all items inside the directory node refers to.
--- @type PopulateChildrenFn
local function populate_children_ls(node)
  if not path_is_directory(node.absolute_filepath) then
    error("Cannot expand " .. node.absolute_filepath .. ": is not a directory")
  end
  local ls_output = vim.system({"ls", "-aF", node.absolute_filepath}, { text = true}):wait()
  if ls_output.code ~= 0 then
    error("Cannot expand " .. node.absolute_filepath .. ": ls failed (unicorn!!)")
  end
  local children = {}
  for child_filename in iter_lines(ls_output.stdout) do
    if child_filename ~= "./" and child_filename ~= "../"  then
      table.insert(children, FileGraph:new({
        absolute_filepath = node.absolute_filepath + child_filename,
        parent = node,
        children = nil,
      }))
    end
  end
  return FileGraph:new({
    absolute_filepath = node.absolute_filepath,
    isDirectory = node.isDirectory,
    parent = node.parent,
    children = children
  })
end

return populate_children_ls
