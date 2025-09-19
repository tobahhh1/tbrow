
local M = {}

--- Return the file represented at row, col on the screen.
--- @param view_state ViewState State of the view
--- @param row integer Row to get filename at
--- @param col integer Column to get filename at
--- @return string
M.file_at_position = function(view_state, row, col)
  local _ = col -- remove unused local warning: we want to force consumers to pass column so view doesn't need to be row-specific in the future.
  return view_state.line_num_to_absolute_filepath[row]
end

--- @param view_state ViewState
M.position_of_file = function(view_state, filepath)
  return view_state.absolute_filepath_to_first_position[filepath]
end

return M
