# Lua API Contract: File Browser

**Branch**: `001-file-browser` | **Date**: 2026-03-25

This document defines the public Lua API surface for the `tbrow` plugin. All functions listed here are accessible via `require("tbrow")` or `require("tbrow").api` and are guaranteed to be stable across minor versions.

## Entry Point

### `require("tbrow")`

Returns the plugin module table with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `setup` | `function(opts?)` | Initialize the plugin |
| `open_curr_win` | `function(path)` | Open browser in current window |
| `api` | `table` | Namespace for programmatic API functions |

---

## Setup

### `tbrow.setup(opts?)`

Initialize the plugin with optional configuration. Must be called before any other API function. Safe to call with no arguments for sensible defaults.

**Parameters**:
- `opts` (`table|nil`): Optional configuration table

**Configuration keys** (all optional):

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `reuse_buffers` | `boolean` | `false` | Reuse existing tbrow buffers for the same root path |
| `indent_string` | `string` | `"  "` (2 spaces) | Indentation string per tree depth level |
| `directories_first` | `boolean` | `true` | Sort directories before files at each level |
| `icons` | `table<string, string>` | `nil` | Override default icon mappings (extension/filename → icon character) |

**Returns**: `nil`

**Side effects**: Registers the `:Tbrow` user command. Initializes the global instance registry.

**Example**:
```lua
require("tbrow"):setup()
-- or with options:
require("tbrow"):setup({
  indent_string = "    ",
  icons = { lua = "🌙" }
})
```

---

## Opening the Browser

### `tbrow.open_curr_win(absolute_filepath)`

Open the file browser in the current window, rooted at the given path. If the current buffer is a file, the tree auto-expands to reveal that file's location.

**Parameters**:
- `absolute_filepath` (`string`): Absolute path to the root directory. If a file path is given, its parent directory is used as root.

**Returns**: `nil`

**Side effects**: Creates a new buffer, sets buffer options (`readonly`, `nomodifiable`, `buftype=nofile`, `filetype=tbrow`), registers the instance in the global registry, attaches keymaps.

---

## Programmatic API

All functions below are accessible via `require("tbrow").api`.

### `tbrow.api.file.file_under_cursor(winnr)`

Return the absolute file path of the entry under the cursor in the specified window.

**Parameters**:
- `winnr` (`integer`): Neovim window number (from `vim.api.nvim_get_current_win()` or similar)

**Returns**: `string|nil` — Absolute file path, or `nil` if the window does not contain a tbrow buffer.

**Example**:
```lua
local path = require("tbrow").api.file.file_under_cursor(vim.api.nvim_get_current_win())
if path then
  print("File under cursor: " .. path)
end
```

### `tbrow.api.file.directory_under_cursor(winnr)`

Return the absolute directory path of the entry under the cursor. If the cursor is on an expanded directory, returns that directory. If on a file or collapsed directory, returns the parent directory.

**Parameters**:
- `winnr` (`integer`): Neovim window number

**Returns**: `string|nil` — Absolute directory path (ending with `/`), or `nil` if the window does not contain a tbrow buffer.

**Example**:
```lua
local dir = require("tbrow").api.file.directory_under_cursor(vim.api.nvim_get_current_win())
```

---

## User Command

### `:Tbrow [path]`

Open the file browser in the current window. If `path` is provided, it's appended to the current working directory. If omitted, uses the current working directory as root.

**Parameters**:
- `path` (`string`, optional): Relative path appended to `vim.fn.getcwd()`

**Examples**:
```vim
:Tbrow           " Open browser at cwd
:Tbrow /src      " Open browser at cwd/src
```

---

## Buffer-Local Keymaps

These keymaps are set on tbrow buffers and do not conflict with Vim navigation motions:

| Key | Action | Description |
|-----|--------|-------------|
| `<CR>` | Primary action | On directory: toggle expand/collapse. On file: open in current window (replaces browser). |
| `p` | Secondary open (stay) | Open file in previous window; cursor stays in browser window. |
| `P` | Secondary open (go) | Open file in previous window; cursor moves to that window. |
| `yd` | Yank directory | Copy the directory path of the entry under cursor to the specified register. |
| `yc` | Yank filepath | Copy the full file path of the entry under cursor to the specified register. |
| `gh` | Toggle hidden | Toggle visibility of hidden files (dotfiles). |
| `<C-l>` | Refresh | Re-read the filesystem and update the tree display. |

---

## Conventions

- All API functions accept explicit parameters; no implicit global context.
- Return values are plain Lua types (`string`, `nil`, `table`). No internal class instances leak across the API boundary.
- API functions do not throw on invalid input; they return `nil` or a descriptive error value.
- All keymaps are buffer-local and do not affect other buffers.
