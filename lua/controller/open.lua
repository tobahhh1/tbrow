local FileGraph = require("model/filegraph")
local draw_filesystem = require("view/drawfilesystem.lua")

local reuse_buffers_default = false
local should_reuse_buffers = function()
  if vim.g.tbrow_reuse_buffers ~= nil then
    return vim.g.tbrow_reuse_buffers
  end
  return reuse_buffers_default
end

--- Returns the expected name of the buffer 
--- given the root path and bufnr.
--- @param absolute_root_path string root filepath
--- @param bufnr integer | nil buffer ID, must be non-nil if vim.g.tbrow_reuse_buffers == false (default)
local function get_buf_name(absolute_root_path, bufnr)
  local buf_name = "[tbrow "
  if not should_reuse_buffers() then
    if not bufnr then error("reuse_buffers is not specified, must pass a buffer ID") end
    buf_name = buf_name .. "(" .. tostring(bufnr) .. ") "
  end
  buf_name = buf_name .. absolute_root_path .. "]"
  return buf_name
end

--- Sets up buffer for use by tbrow.
--- @param absolute_root_path string
--- @param bufnr integer
local function set_buf_options(absolute_root_path, bufnr)
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].filetype = "tbrow"
  vim.api.nvim_buf_set_name(bufnr, get_buf_name(absolute_root_path, bufnr))
end

local function init_filegraph(absolute_root_path)
  return FileGraph({
    absolute_filepath = absolute_root_path,
  })
end

--- Open tbrow in a window.
local function open(absolute_root_path, buf)
  local bufnr = -1
  if should_reuse_buffers() then
    bufnr = vim.fn.bufnr(get_buf_name(absolute_root_path))
  end
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, false)
  end
  set_buf_options(absolute_root_path, buf)
  local filegraph = init_filegraph(absolute_root_path)
  draw_filesystem(
    filegraph,
    {},
    bufnr
  )
end

return open
