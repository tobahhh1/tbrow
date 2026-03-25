local M = {}

local function split(s, delimiter)
  local result = {}
  for match in string.gmatch(s, "([^"..delimiter.."]+)") do
      table.insert(result, match)
  end
  return result
end

local function to_absolute_paths(relative_paths)
  local result = {}
  for _, path in ipairs(relative_paths) do
    table.insert(result, vim.fs.normalize(vim.fn.fnamemodify(path,":p")))
  end
  return result
end


local function is_git_repo()
  local result = vim.fn.system("git rev-parse --git-dir 2>/dev/null")
  return vim.v.shell_error == 0 and result ~= ""
end

local function git_unstaged_changes()
  if not is_git_repo() then return {} end
  return to_absolute_paths(split(vim.fn.system("git diff --name-only"), "\n"))
end

local function git_staged_changes()
  if not is_git_repo() then return {} end
  return to_absolute_paths(split(vim.fn.system("git diff --name-only --staged"), "\n"))
end

local function git_unmerged_changes()
  if not is_git_repo() then return {} end
  return to_absolute_paths(split(vim.fn.system("git diff --name-only --diff-filter=U"), "\n"))
end

local function git_untracked_files()
  if not is_git_repo() then return {} end
  return to_absolute_paths(split(vim.fn.system("git ls-files --others --exclude-standard"), "\n"))
end

local function list_to_set(list)
  local set = {}
  for _, val in ipairs(list) do
    set[val] = true
  end
  return set
end

local function get_all_roots(fname)
  local full_root = "/"
  local result = {}
  for root in string.gmatch(fname, "([^/]+/?)") do
    full_root = full_root .. root
    table.insert(result, full_root)
  end
  return result
end

local function map(func, tbl)
  local result = {}
  for i, val in ipairs(tbl) do
    result[i] = func(val)
  end
  return result
end

local function flatten(nestedTable)
    local flatTable = {}

    local function deepFlatten(currentTable)
        for _, value in ipairs(currentTable) do
            if type(value) == "table" then
                deepFlatten(value)
            else
                table.insert(flatTable, value)
            end
        end
    end

    deepFlatten(nestedTable)
    return flatTable
end

--- @class GitStatusStore
--- @field unstaged table<string, boolean>
--- @field staged table<string, boolean>
--- @field unmerged table<string, boolean>
--- @field untracked table<string, boolean>
local prototype = {
  unstaged = {},
  staged = {},
  unmerged = {},
  untracked = {},
}

--- @param o GitStatusStore|nil
--- @return GitStatusStore
function prototype:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return GitStatusStore
function prototype:refreshed()
  if not is_git_repo() then
    return prototype:new({ unstaged = {}, staged = {}, unmerged = {}, untracked = {} })
  end
  return prototype:new({
    unstaged  = list_to_set(flatten(map(get_all_roots, git_unstaged_changes()))),
    staged    = list_to_set(flatten(map(get_all_roots, git_staged_changes()))),
    unmerged  = list_to_set(flatten(map(get_all_roots, git_unmerged_changes()))),
    untracked = list_to_set(flatten(map(get_all_roots, git_untracked_files()))),
  })
end

M.GitStatusStore = prototype

return M
