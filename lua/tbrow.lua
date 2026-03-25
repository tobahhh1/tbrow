local initialize = require("controller.initialize")
local actions = require("controller.actions")
local draw_filesystem = require("view.drawfilesystem")
local path_utils = require("utils.path")
local diagnostics = require("view.diagnostic")
local git_status_view = require("view.gitstatus")
local debounce = require("utils.debounce")
local populatechildren = require("model.populatechildren")
local file_api = require("api.file")

local M = {}

--- Attach keymaps and autocmds to a tbrow buffer.
--- @param init_model_state ModelState
--- @param init_view_state ViewState
--- @param winnr integer
--- @param bufnr integer
local function setup_buffer(init_model_state, init_view_state, winnr, bufnr)
  local model_state = init_model_state
  local view_state = init_view_state

  local function update_global_instance()
    if TbrowBufnrToInstance == nil then
      TbrowBufnrToInstance = {}
    end
    TbrowBufnrToInstance[bufnr] = {
      model_state = model_state,
      view_state = view_state
    }
  end
  update_global_instance()

  local function toggle_directory_or_open_file()
    local filepath = actions.file_at_position_default_to_cursor(view_state, winnr)
    if path_utils.path_is_directory(filepath) then
      model_state = actions.toggle_directory_expanded(model_state, view_state, winnr):withDiagnosticsRefreshed():withGitStatusRefreshed()
      view_state = draw_filesystem(view_state, model_state, bufnr)
    else
      actions.open_file("0", view_state, winnr)
    end
    update_global_instance()
  end
  vim.keymap.set("n", "<CR>", toggle_directory_or_open_file, { buffer = bufnr })

  local function open_in_prev_window()
    actions.open_file("wincmd p", view_state, winnr)
    vim.api.nvim_set_current_win(winnr)
    update_global_instance()
  end
  vim.keymap.set("n", "p", open_in_prev_window, { buffer = bufnr })

  local function open_in_and_navigate_to_prev_window()
    actions.open_file("wincmd p", view_state, winnr)
    update_global_instance()
  end
  vim.keymap.set("n", "P", open_in_and_navigate_to_prev_window, { buffer = bufnr })

  local function yank_directory()
    local reg = vim.v.register
    local filepath = actions.file_at_position_default_to_cursor(view_state, winnr)
    if path_utils.path_is_directory(filepath) then
      vim.fn.setreg(reg, filepath)
    else
      local root, _ = path_utils.split_root_and_filename(filepath)
      vim.fn.setreg(reg, root)
    end
  end
  vim.keymap.set("n", "yd", yank_directory, { buffer = bufnr })

  local function yank_filepath()
    local reg = vim.v.register
    local filepath = actions.file_at_position_default_to_cursor(view_state, winnr)
    vim.fn.setreg(reg, filepath)
  end
  vim.keymap.set("n", "yc", yank_filepath, { buffer = bufnr })

  local function refresh_diagnostics()
    model_state = model_state:withDiagnosticsRefreshed()
    view_state = diagnostics.draw_diagnostics(view_state, model_state, bufnr)
    update_global_instance()
  end

  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = debounce.with_debounce(refresh_diagnostics, 100)
  })

  local function refresh_git_status()
    model_state = model_state:withGitStatusRefreshed()
    view_state = git_status_view.draw_git_status(view_state, model_state, bufnr)
    update_global_instance()
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = debounce.with_debounce(refresh_git_status, 200)
  })

  local function refresh_filesystem()
    model_state = populatechildren.with_root_refreshed(model_state):withGitStatusRefreshed()
    view_state = draw_filesystem(view_state, model_state, bufnr)
    update_global_instance()
  end
  vim.keymap.set("n", "<C-l>", refresh_filesystem, { buffer = bufnr })

  local function toggle_hidden()
    model_state = actions.toggle_hidden(model_state)
    view_state = draw_filesystem(view_state, model_state, bufnr)
    update_global_instance()
  end
  vim.keymap.set("n", "gh", toggle_hidden, { buffer = bufnr })

  -- Keymap audit (FR-002, constitution principle III):
  -- <CR>: Not a default normal-mode motion (it moves cursor down, but we override intentionally for primary action)
  -- p/P: Override put commands, acceptable since tbrow buffers are nomodifiable
  -- yd/yc: Invalid yank sequences in default Vim, safe to use
  -- <C-l>: Overrides screen redraw, acceptable since we provide our own refresh
  -- gh: Enters Select mode in Vim; rarely used and buffer-local override is acceptable
  -- All standard navigation (j/k/gg/G/Ctrl-d/Ctrl-u/w/b/e/f/F/t/T/;/,/H/M/L//{/}) is preserved.
end

--- Open tbrow in the current window.
--- @param absolute_filepath string
function M.open_curr_win(absolute_filepath)
  local winnr = vim.api.nvim_get_current_win()
  if not path_utils.path_is_directory(absolute_filepath) then
    absolute_filepath = absolute_filepath .. "/"
  end
  local selected_file = absolute_filepath
  if vim.bo.buftype == "" then
    local buffer_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winnr))
    if buffer_name ~= "" then
      selected_file = buffer_name
    end
  end
  local model_state = initialize.new_tbrow_instance(absolute_filepath, selected_file)
  local view_state = initialize.open_in_win(model_state, winnr, selected_file)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  setup_buffer(model_state, view_state, winnr, bufnr)
end

--- Open tbrow in a specified window (for API use).
--- @param absolute_filepath string
--- @param winnr integer
function M._open_in_win(absolute_filepath, winnr)
  if not path_utils.path_is_directory(absolute_filepath) then
    absolute_filepath = absolute_filepath .. "/"
  end
  local model_state = initialize.new_tbrow_instance(absolute_filepath)
  local view_state = initialize.open_in_win(model_state, winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  setup_buffer(model_state, view_state, winnr, bufnr)
end

function M:setup(opts)
  opts = opts or {}

  -- OPTIONS
  vim.g.tbrow_reuse_buffers = opts.reuse_buffers or false
  vim.g.tbrow_indent_string = opts.indent_string or "  "
  vim.g.tbrow_directories_first = opts.directories_first ~= nil and opts.directories_first or true

  if opts.icons ~= nil then
    vim.g.tbrow_icons = opts.icons
  end

  --- Internal mapping from buffer number to Tbrow instance.
  if TbrowBufnrToInstance == nil then
    TbrowBufnrToInstance = {}
  end

  -- COMMANDS
  vim.api.nvim_create_user_command("Tbrow", function(args)
    M.open_curr_win(args.nargs == 1 and vim.fn.getcwd() .. args.fargs[1] or vim.fn.getcwd())
  end, { nargs = '?' })
end

M.api = {
  open_curr_win = M.open_curr_win,
  open_in_win = function(path, winnr) M._open_in_win(path, winnr) end,
  file = file_api,
}

return M
