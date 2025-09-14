local open = require("controller/open")

-- OPTIONS
--- When opening Tbrow to a root already in the filesystem, reuse that buffer.
vim.g.tbrow_reuse_buffers = false

--- Indent with this sequence of characters. Defaults to "  ", or two spaces.
--- TODO: Move to different file so that importing this multiple times doesn't reset it.
vim.g.tbrow_indent_string = "  "

-- COMMANDS
vim.api.nvim_create_user_command("Tbrow", open, {})
