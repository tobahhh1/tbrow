



local function get_max_diag_severity_by_file_lu(diagnostics)
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


local diagnosticStore = {
  max_diag_severity_by_file_lu = {}
}

function diagnosticStore:refresh_max_diag_severity()
  max_diag_severity_by_file_lu = {}
end
