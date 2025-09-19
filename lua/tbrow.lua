local initialize = require("controller.initialize")
local actions = require("controller.actions")
local draw_filesystem = require("view.drawfilesystem")
local path_utils = require("utils.path")
local debounce = require("utils.debounce")

local M = {}

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

  -- Attach keymaps to buffer
  local function toggle_directory_or_open_file()
    local success, result = pcall(
      function()
        return actions.toggle_directory_expanded(model_state, view_state, winnr)
      end
    )
    if success then
      model_state = result:withDiagnosticsRefreshed()
      view_state = draw_filesystem(view_state, model_state, bufnr)
    else
      actions.open_file("0", view_state, winnr)
    end
  end
  vim.keymap.set("n", "<CR>", toggle_directory_or_open_file, { buffer = true })

  -- Open file in previous window
  local function open_in_prev_window()
    actions.open_file("wincmd p", view_state, winnr)
    vim.api.nvim_set_current_win(winnr)
  end
  vim.keymap.set("n", "p", open_in_prev_window, {buffer = true})

  local function open_in_and_navigate_to_prev_window()
    actions.open_file("wincmd p", view_state, winnr)
  end
  vim.keymap.set("n", "P", open_in_and_navigate_to_prev_window, {buffer = true})

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
  --- yd doesn't overwrite any other yank commands (it's invalid), so we are free to use it here.
  vim.keymap.set("n", "yd", yank_directory, {buffer = true})

  local function yank_filepath()
    local reg = vim.v.register
    local filepath = actions.file_at_position_default_to_cursor(view_state, winnr)
    vim.fn.setreg(reg, filepath)
  end
  --- yc doesn't overwrite any other yank commands (it's invalid), so we are free to use it here.
  vim.keymap.set("n", "yc", yank_filepath, {buffer = true})

end

function M:setup()
  -- OPTIONS
  --- When opening Tbrow to a root already in the filesystem, reuse that buffer.
  vim.g.tbrow_reuse_buffers = false

  --- Indent with this sequence of characters. Defaults to "  ", or two spaces.
  --- TODO: Move to different file so that importing this multiple times doesn't reset it.
  vim.g.tbrow_indent_string = "  "

  -- COMMANDS
  vim.api.nvim_create_user_command("Tbrow", function(args)
    M.open_curr_win(args.nargs == 1 and vim.fn.getcwd() .. args.fargs[1] or vim.fn.getcwd())
  end, { nargs = '?' })
end

return M
