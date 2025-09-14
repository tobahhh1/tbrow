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


local function git_unstaged_changes()
  return to_absolute_paths(split(vim.fn.system("git diff --name-only"), "\n"))
end

local function git_staged_changes()
  return to_absolute_paths(split(vim.fn.system("git diff --name-only --staged"), "\n"))
end

local function git_unmerged_changes()
  return to_absolute_paths(split(vim.fn.system("git diff --name-only --diff-filter=U"), "\n"))
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
                deepFlatten(value) -- Recursively flatten sub-tables
            else
                table.insert(flatTable, value) -- Add non-table elements to the flat table
            end
        end
    end

    deepFlatten(nestedTable)
    return flatTable
end

local gitStore = {
  git_cache = { unstaged = {}, staged = {}, unmerged = {} }
}

function gitStore:refresh_git_cache()
  self.git_cache.unstaged = list_to_set(flatten(map(get_all_roots, git_unstaged_changes())))
  self.git_cache.staged   = list_to_set(flatten(map(get_all_roots, git_staged_changes())))
  self.git_cache.unmerged = list_to_set(flatten(map(get_all_roots, git_unmerged_changes())))
end

return gitStore
