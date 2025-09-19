local M = {}

function M.with_debounce(fn, ms)
  local timer = nil
  local timer_running = false
  return function (...)
    local argv = { ... }
    if timer and timer_running then
      timer_running = false
      timer:stop()
      timer:close()
    end
    timer = vim.defer_fn(function()
      fn(unpack(argv))
    end, ms)
    timer_running = true
  end
end

return M
