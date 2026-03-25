local Actions = require("controller.actions")
local PathUtil = require("utils.path")
local draw_filesystem = require("view.drawfilesystem")
local populatechildren = require("model.populatechildren")

local M = {}

--- Return the absolute filepath under the cursor in the given window.
--- @param winnr integer Window number
--- @return string | nil Absolute filepath under cursor, or nil if not found or if not a tbrow window.
function M.file_under_cursor(winnr)
  local tbrow_instance_for_window = TbrowBufnrToInstance[vim.api.nvim_win_get_buf(winnr)]
  if tbrow_instance_for_window == nil then
    return nil
  end
  local view_state = tbrow_instance_for_window.view_state
  local absolute_filepath = Actions.file_at_position_default_to_cursor(view_state, winnr)
  return absolute_filepath
end

--- Return the absolute directory path under the cursor in the given window.
--- @param winnr integer Window number
--- @return string | nil Absolute directory path under cursor, or nil if not found or if not a tbrow window.
function M.directory_under_cursor(winnr)
  local tbrow_instance_for_window = TbrowBufnrToInstance[vim.api.nvim_win_get_buf(winnr)]
  if tbrow_instance_for_window == nil then
    return nil
  end
  --- @type ViewState
  local view_state = tbrow_instance_for_window.view_state
  --- @type ModelState
  local model_state = tbrow_instance_for_window.model_state
  local absolute_path = Actions.file_at_position_default_to_cursor(view_state, winnr)
  local node = model_state:getFileGraphNodeAtAbsoluteFilepath(absolute_path)
  if node == nil then
    error("Invalid state: View pointed at incorrect absolute filepath in position")
  end
  -- Allows the user to add to a directory if it has no items in it: if it is expanded,
  -- return it.
  if node:isExpanded() then
    return absolute_path
  else
    local dir, _ = PathUtil.split_root_and_filename(absolute_path)
    return dir
  end
end

--- Open the file browser in a specific window.
--- @param absolute_filepath string Absolute path to root directory
--- @param winnr integer Window number to open the browser in
function M.open_in_win(absolute_filepath, winnr)
  local tbrow = require("tbrow")
  tbrow._open_in_win(absolute_filepath, winnr)
end

--- Toggle hidden file visibility in the browser at the given window.
--- @param winnr integer Window number
--- @return boolean | nil New show_hidden value, or nil if not a tbrow window
function M.toggle_hidden(winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local instance = TbrowBufnrToInstance[bufnr]
  if instance == nil then
    return nil
  end
  local model_state = Actions.toggle_hidden(instance.model_state)
  local view_state = draw_filesystem(instance.view_state, model_state, bufnr)
  TbrowBufnrToInstance[bufnr] = {
    model_state = model_state,
    view_state = view_state,
  }
  return model_state.show_hidden
end

--- Refresh the file tree in the browser at the given window.
--- @param winnr integer Window number
--- @return boolean success True if refresh succeeded, nil if not a tbrow window
function M.refresh(winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local instance = TbrowBufnrToInstance[bufnr]
  if instance == nil then
    return nil
  end
  local model_state = populatechildren.with_root_refreshed(instance.model_state)
  local view_state = draw_filesystem(instance.view_state, model_state, bufnr)
  TbrowBufnrToInstance[bufnr] = {
    model_state = model_state,
    view_state = view_state,
  }
  return true
end

return M
