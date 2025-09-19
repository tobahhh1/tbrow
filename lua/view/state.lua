local M = {}

--- Represents the current state of the view. view/ module uses this to track
--- what is currently on the screen; and may require it for a few functions.
--- Any fields or methods on this class should not be called by consumers
--- and can change at any moment.
--- @class ViewState 
--- @field line_num_to_absolute_filepath table<integer, string>
--- @field absolute_filepath_to_first_position table<string, {row: integer, col: integer}>
local prototype = {
  line_num_to_absolute_filepath = {},
  absolute_filepath_to_first_position = {}
}

--- @param o ViewState | nil
--- @return ViewState
function prototype:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end


M.ViewState = prototype
return M

