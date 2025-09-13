local FileGraph = require("model/filegraph")

--- @param s string
local function iter_lines(s)
  return string.gmatch(s, ".*$")
end

--- @param s string
local function path_is_directory(s)
  return not not string.match(s, ".*/$")
end

--- @alias ExpandFn fun(node: FileGraph): FileGraph

--- Return a copy of node where children contains
--- all items inside the directory node refers to.
--- @type ExpandFn
local function expand_ls(node)
  if not node.isDirectory then
    error("Cannot expand " .. node.name .. ": is not a directory")
  end
  local ls_output = vim.system({"ls", "-aF", node.name}, { text = true}):wait()
  if ls_output.code ~= 0 then
    error("Cannot expand " .. node.name .. ": ls failed (unicorn!!)")
  end
  local children = {}
  for child_filename in iter_lines(ls_output.stdout) do
    if child_filename ~= "./" and child_filename ~= "../"  then
      table.insert(children, FileGraph:new({
        name = node.name + child_filename,
        isDirectory = path_is_directory(child_filename),
        parent = node,
        children = nil,
      }))
    end
  end
  return FileGraph:new({
    name = node.name,
    isDirectory = node.isDirectory,
    parent = node.parent,
    children = children
  })
end

return expand_ls
