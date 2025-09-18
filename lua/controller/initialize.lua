local FileGraph = require("model.filegraph")
local modelstate = require("model.state")
local draw_filesystem = require("view.drawfilesystem")
local diagnostic = require("model.diagnostic")

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
--- @param root_path_from_cwd string root filepath
--- @param bufnr integer | nil buffer ID, must be non-nil if vim.g.tbrow_reuse_buffers == false (default)
local function get_buf_name(root_path_from_cwd, bufnr)
  local buf_name = "[tbrow "
  if not should_reuse_buffers() then
    if not bufnr then error("reuse_buffers is not specified, must pass a buffer ID") end
    buf_name = buf_name .. "(" .. tostring(bufnr) .. ") "
  end
  buf_name = buf_name .. root_path_from_cwd .. "]"
  return buf_name
end

--- Sets up buffer for use by tbrow.
--- @param root_path_from_cwd string
--- @param bufnr integer
local function set_buf_options(root_path_from_cwd, bufnr)
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].filetype = "tbrow"
  vim.api.nvim_buf_set_name(bufnr, get_buf_name(root_path_from_cwd, bufnr))
end

--- Returns a buffer number for a new tbrow instance just opened 
--- by the user for a given file. Reuse an existing buffer
--- if should_reuse_buffers().
--- @param root_path_from_cwd string
--- @return integer
function M.get_or_create_buf(root_path_from_cwd)
  local bufnr = -1
  if should_reuse_buffers() then
    bufnr = vim.fn.bufnr(get_buf_name(root_path_from_cwd))
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
  local root_path_from_cwd = model_state:getRoot():getFilepathFromCwd()
  set_buf_options(root_path_from_cwd, bufnr)
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
function M.open_in_win(model_state, winnr)
  local bufnr = M.get_or_create_buf(model_state:getRoot():getFilepathFromCwd())
  local view_state = M.initialize_buf(model_state, bufnr)
  vim.api.nvim_win_set_buf(winnr, bufnr)
  return view_state
end

--- @param filepath_from_cwd string
function M.new_tbrow_instance(filepath_from_cwd)
  local root = FileGraph:new({
      filepath_from_cwd = filepath_from_cwd
    })
  -- TODO move object creation logic to somewhere that the controller won't own it.
  return modelstate.ModelState:new({
    root = root,
    filepath_from_cwd_to_graph_node = {
      [filepath_from_cwd] = root
    },
    diagnostic_store = diagnostic.DiagnosticStore:new({
      max_diag_severity_by_file_lu = {}
    })
  })
end

return M
