local M = {}

function M.get_max_diag_severity_by_file_lu(diagnostics)
  local lookup = {}
  for _, d in ipairs(diagnostics or vim.diagnostic.get()) do
    local fname = vim.api.nvim_buf_get_name(d.bufnr)
    if fname ~= "" then
      local full_root = "/"
      for root in string.gmatch(fname, "([^/]+/?)") do
        full_root = full_root .. root
        local severity = lookup[full_root] or vim.diagnostic.severity.HINT + 1
        if d.severity < severity then
          lookup[full_root] = d.severity
        end
      end
    end
  end
  return lookup
end

--- @class DiagnosticStore
--- @field max_diag_severity_by_file_lu table<string, vim.diagnostic.Severity> 
local prototype = {}

--- @param o DiagnosticStore
--- @return DiagnosticStore
function prototype:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function prototype:maxDiagSeverityByPathFromCwd(path_from_cwd)
  return self.max_diag_severity_by_file_lu(path_from_cwd)
end


M.DiagnosticStore = prototype

return M
