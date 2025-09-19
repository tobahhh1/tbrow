local fileatposition = require("view.fileatposition")
local path_utils = require("utils.path")
local populatechildren = require("model.populatechildren")

local M = {}

function M.file_at_position_default_to_cursor(view_state, winnr, row, col)
  if row == nil and col == nil then
    local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
    row = cursor_pos[1]
    col = cursor_pos[2]
  elseif row == nil or col == nil then
    error("Must specify both a row and a column, or neither")
  end
  return fileatposition.file_at_position(view_state, row, col)
end

local function directory_at_position_default_to_cursor(view_state, winnr, row, col)
  local filepath = M.file_at_position_default_to_cursor(view_state, winnr, row, col)
  if not path_utils.path_is_directory(filepath) then
    error("Cannot expand " .. filepath .. ": it isn't a directory!")
  end
  return filepath
end

--- Expands the directory at the specified position. Defaults to using the cursor position.
--- @param model_state ModelState
--- @param view_state ViewState Current state of the view in the window number.
--- @param winnr integer Window ID, or 0 for current window
--- @param row integer | nil Row number, or nil for current position
--- @param col integer | nil Column number, or nil for current position.
M.expand_directory = function(model_state, view_state, winnr, row, col)
  local directory = directory_at_position_default_to_cursor(view_state, winnr, row, col)
  return populatechildren.with_file_expanded(model_state, directory)
end

--- Collapses the directory at the specified position. Defaults to using the cursor position.
--- @param model_state ModelState
--- @param view_state ViewState Current state of the view in the window number.
--- @param winnr integer Window ID, or 0 for current window
--- @param row integer | nil Row number, or nil for current position
--- @param col integer | nil Column number, or nil for current position.
M.collapse_directory = function(model_state, view_state, winnr, row, col)
  local directory = directory_at_position_default_to_cursor(view_state, winnr, row, col)
  return populatechildren.with_file_collapsed(model_state, directory)
end

--- Collapses or expands the directory at the specified position. Defaults to using the cursor position.
--- @param model_state ModelState
--- @param view_state ViewState Current state of the view in the window number.
--- @param winnr integer Window ID, or 0 for current window
--- @param row integer | nil Row number, or nil for current position
--- @param col integer | nil Column number, or nil for current position.
M.toggle_directory_expanded = function(model_state, view_state, winnr, row, col)
  local directory = directory_at_position_default_to_cursor(view_state, winnr, row, col)
  local node = model_state:getFileGraphNodeAtAbsoluteFilepath(directory)
  if node == nil then
    error("Could not find " .. directory)
  end
  if node:isExpanded() then
    return populatechildren.with_file_collapsed(model_state, directory)
  else
    return populatechildren.with_file_expanded(model_state, directory)
  end
end

M.open_file = function(wincmd, view_state, tbrow_winnr, row, col)
  local file = M.file_at_position_default_to_cursor(view_state, tbrow_winnr, row, col)
  vim.cmd(wincmd)
  vim.cmd("e " .. file)
end

return M
