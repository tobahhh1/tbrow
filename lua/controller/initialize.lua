local FileGraph = require("model.filegraph")
local modelstate = require("model.state")
local draw_filesystem = require("view.drawfilesystem")
local diagnostic = require("model.diagnostic")
local populatechildren = require("model.populatechildren")
local path_utils = require("utils.path")
local fileatposition = require("view.fileatposition")

local M = {}

local reuse_buffers_default = false
local should_reuse_buffers = function()
  if vim.g.tbrow_reuse_buffers ~= nil then
    return vim.g.tbrow_reuse_buffers
  end
  return reuse_buffers_default
end

--- Returns the expected name of the buffer 
--- given the root path and bufnr.
--- @param absolute_filepath string root filepath
--- @param bufnr integer | nil buffer ID, must be non-nil if vim.g.tbrow_reuse_buffers == false (default)
local function get_buf_name(absolute_filepath, bufnr)
  local buf_name = "[tbrow "
  if not should_reuse_buffers() then
    if not bufnr then error("reuse_buffers is not specified, must pass a buffer ID") end
    buf_name = buf_name .. "(" .. tostring(bufnr) .. ") "
  end
  buf_name = buf_name .. absolute_filepath .. "]"
  return buf_name
end

--- Sets up buffer for use by tbrow.
--- @param absolute_filepath string
--- @param bufnr integer
local function set_buf_options(absolute_filepath, bufnr)
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].filetype = "tbrow"
  vim.api.nvim_buf_set_name(bufnr, get_buf_name(absolute_filepath, bufnr))
end

--- Returns a buffer number for a new tbrow instance just opened 
--- by the user for a given file. Reuse an existing buffer
--- if should_reuse_buffers().
--- @param absolute_filepath string
--- @return integer
function M.get_or_create_buf(absolute_filepath)
  local bufnr = -1
  if should_reuse_buffers() then
    bufnr = vim.fn.bufnr(get_buf_name(absolute_filepath))
  end
  if bufnr == -1 then
    return vim.api.nvim_create_buf(false, true)
  else
    return bufnr
  end
end

--- Take an arbitrary buffer number
--- and use it to render model_state in Tbrow.
--- Return the ViewState currently rendered in the buffer.
--- @param model_state ModelState
--- @param bufnr integer
function M.initialize_buf(model_state, bufnr)
  local root_absolute_filepath = model_state:getRoot():absoluteFilepath()
  set_buf_options(root_absolute_filepath, bufnr)
  return draw_filesystem(
    nil,
    model_state,
    bufnr
  )
end

--- Take an arbitrary window number
--- and use it to render model_state in Tbrow.
--- @param model_state ModelState
--- @param winnr integer
--- @param selected_file string | nil
function M.open_in_win(model_state, winnr, selected_file)
  local bufnr = M.get_or_create_buf(model_state:getRoot():absoluteFilepath())
  local view_state = M.initialize_buf(model_state, bufnr)
  vim.api.nvim_win_set_buf(winnr, bufnr)
  if selected_file ~= nil then
    local pos = fileatposition.position_of_file(view_state, selected_file)
    if pos == nil then
      error("Cannot find file " .. selected_file)
    end
    vim.api.nvim_win_set_cursor(
      winnr,
      {pos.row, pos.col}
    )
  end
  return view_state
end

--- @param root_filepath string
function M.new_tbrow_instance(root_filepath, selected_file)
  local root = FileGraph:new({
      absolute_filepath = root_filepath
    })
  -- TODO move object creation logic to somewhere that the controller won't own it.
  local model_state = modelstate.ModelState:new({
    root = root,
    diagnostic_store = diagnostic.DiagnosticStore:new({
      max_diag_severity_by_file_lu = {}
    })
  })
  if selected_file ~= nil then
    if not path_utils.path_is_directory(selected_file) then
      local dir, _ = path_utils.split_root_and_filename(selected_file)
      selected_file = dir
    end
    return populatechildren.with_file_expanded(model_state, selected_file)
  end
  return model_state
end

return M
