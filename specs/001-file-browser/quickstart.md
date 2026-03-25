# Quickstart: File Browser (tbrow)

**Branch**: `001-file-browser` | **Date**: 2026-03-25

## Prerequisites

- Neovim ≥ 0.9
- A Nerd Font installed in your terminal (for file-type icons)
- `git` in your PATH (for git status indicators; optional)

## Installation

Place or symlink the plugin directory into your Neovim package path:

```
~/.local/share/nvim/site/pack/custom/start/tbrow/
```

Or use your preferred plugin manager pointing to the repository.

## Minimal Setup

Add to your `init.lua`:

```lua
require("tbrow"):setup()
```

This registers the `:Tbrow` command and initializes defaults. No arguments required.

## Basic Usage

1. **Open the browser**: Run `:Tbrow` or call `require("tbrow").open_curr_win(vim.fn.getcwd())` from Lua.
2. **Navigate**: Use `j`/`k`, `gg`/`G`, `/` search, `Ctrl-d`/`Ctrl-u` — all standard Vim motions work.
3. **Expand/collapse directories**: Press `<CR>` on a directory.
4. **Open a file**: Press `<CR>` on a file (opens in current window), or `p` to open in the previous window while keeping the browser visible.
5. **Toggle hidden files**: Press `gh` to show/hide dotfiles.
6. **Refresh**: Press `<C-l>` to re-read the filesystem.
7. **Yank paths**: `yd` copies the directory path, `yc` copies the full file path.

## API Example

```lua
local tbrow = require("tbrow")

-- Query the file under cursor in a tbrow window
local winnr = vim.api.nvim_get_current_win()
local path = tbrow.api.file.file_under_cursor(winnr)
print(path)  -- e.g., "/home/user/project/src/main.lua"
```

## Development

**Run tests** (once test harness is established):

```sh
nvim --headless -u NONE -l tests/run.lua
```

**Project structure**: See `specs/001-file-browser/plan.md` for the full source layout and architecture overview.
