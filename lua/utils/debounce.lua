local M = {}

function M.with_debounce(fn, ms)
  local timer = nil
  return function (...)
    local argv = { ... }
    if timer then
      timer:stop()
      timer:close()
    end
    timer = vim.defer_fn(function()
      fn(unpack(argv))
      timer = nil
    end, ms)
  end
end

return M
