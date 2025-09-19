local M = {}

local netrw_extmark_diagnostic_namespace = vim.api.nvim_create_namespace("netrw_extmark_diagnostic_namespace")

local severity_to_hl_group = {
  [vim.diagnostic.severity.HINT] = vim.api.nvim_get_hl_id_by_name("DiagnosticHint"),
  [vim.diagnostic.severity.INFO] = vim.api.nvim_get_hl_id_by_name("DiagnosticInfo"),
  [vim.diagnostic.severity.WARN] = vim.api.nvim_get_hl_id_by_name("DiagnosticWarn"),
  [vim.diagnostic.severity.ERROR] = vim.api.nvim_get_hl_id_by_name("DiagnosticError"),
}

-- local severity_to_underline_hl_group = {
--   [vim.diagnostic.severity.HINT] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineHint"),
--   [vim.diagnostic.severity.INFO] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineInfo"),
--   [vim.diagnostic.severity.WARN] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineWarn"),
--   [vim.diagnostic.severity.ERROR] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineError"),
-- }


local function append_extmark(bufnr, line, ns, text, hl_group)
  vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
    virt_text={
      {text, hl_group}
    },
    priority=2
  })
end

local function draw_diagnostic(bufnr, line, severity)
  append_extmark(bufnr, line, netrw_extmark_diagnostic_namespace, vim.diagnostic.config().signs.text[severity], severity_to_hl_group[severity])
end

--- @param prev_state ViewState
--- @param model_state ModelState Root node of file graph to draw
--- @param bufnr integer Buffer number to draw to
--- @return ViewState
local function draw_diagnostics(prev_state, model_state, bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, netrw_extmark_diagnostic_namespace, 0, -1)
  local diagnostics = model_state.diagnostic_store.max_diag_severity_by_file_lu
  local line_number_to_file_info = prev_state.line_num_to_absolute_filepath

  for line_num, file_name in pairs(line_number_to_file_info) do
    if diagnostics[file_name] then
      draw_diagnostic(bufnr, line_num - 1, diagnostics[file_name])
    end
  end
  return prev_state
end

M.draw_diagnostics = draw_diagnostics
return M
