local M = {}

local tbrow_git_status_ns = vim.api.nvim_create_namespace("tbrow_git_status_ns")

vim.api.nvim_set_hl(0, "TbrowGitStaged", { fg = "#6bc644", default = true })
vim.api.nvim_set_hl(0, "TbrowGitUnstaged", { fg = "#b54418", default = true })
vim.api.nvim_set_hl(0, "TbrowGitUntracked", { fg = "#b54418", default = true })
vim.api.nvim_set_hl(0, "TbrowGitUnmerged", { fg = "#cc0000", default = true })

local status_config = {
  { key = "staged",    symbol = " S", hl = "TbrowGitStaged" },
  { key = "unstaged",  symbol = " M", hl = "TbrowGitUnstaged" },
  { key = "untracked", symbol = " ?", hl = "TbrowGitUntracked" },
  { key = "unmerged",  symbol = " U", hl = "TbrowGitUnmerged" },
}

--- @param view_state ViewState
--- @param model_state ModelState
--- @param bufnr integer
--- @return ViewState
local function draw_git_status(view_state, model_state, bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, tbrow_git_status_ns, 0, -1)
  local git_store = model_state.git_status_store
  if git_store == nil then
    return view_state
  end
  local line_number_to_file_info = view_state.line_num_to_absolute_filepath

  for line_num, file_path in pairs(line_number_to_file_info) do
    local virt_text = {}
    local user_marks = vim.g.tbrow_git_marks
    for _, status in ipairs(status_config) do
      if git_store[status.key][file_path] then
        local text = status.symbol
        if user_marks and user_marks[status.key] and user_marks[status.key].text ~= nil then
          text = user_marks[status.key].text
        end
        if text ~= "" then
          table.insert(virt_text, { text, status.hl })
        end
      end
    end
    if #virt_text > 0 then
      vim.api.nvim_buf_set_extmark(bufnr, tbrow_git_status_ns, line_num - 1, 0, {
        virt_text = virt_text,
        virt_text_pos = "eol",
        priority = 3,
      })
    end
  end
  return view_state
end

M.draw_git_status = draw_git_status
return M
