local initialize = require("controller.initialize")
local actions = require("controller.actions")
local draw_filesystem = require("view.drawfilesystem")

local M = {}

--- Open tbrow in the current window.
--- @param root_path_from_cwd string
function M.open_curr_win(root_path_from_cwd)
  local winnr = vim.api.nvim_get_current_win()
  local model_state = initialize.new_tbrow_instance(root_path_from_cwd)
  local view_state = initialize.open_in_win(model_state, winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  -- Attach keymaps to buffer
  local function toggle_directory_or_open_file()
    local success, result = pcall(
      function()
        return actions.toggle_directory_expanded(model_state, view_state, winnr)
      end
    )
    if success then
      model_state = result
      view_state = draw_filesystem(view_state, model_state, bufnr)
    else
      actions.open_file("enew", view_state, winnr)
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
    M.open_curr_win(args.nargs == 1 and args.fargs[1] or "./")
  end, { nargs = '?' })
end

return M
