# Quickstart: Git Status Extmark in File Browser

**Branch**: `002-git-status-extmark` | **Date**: 2026-03-25

## Prerequisites

- Neovim ≥ 0.9
- `git` in your PATH
- A Nerd Font installed in your terminal (for file-type icons)
- tbrow plugin installed and configured (see `specs/001-file-browser/quickstart.md`)

## What This Feature Adds

Git status indicators appear at the end of each file entry line in the tbrow file browser, next to any existing diagnostic indicators. At a glance, you can see which files have uncommitted changes.

## Git Status Indicators

| Indicator | Meaning | Default Color |
|-----------|---------|---------------|
| `M` | File has unstaged (modified) changes | Warning (yellow/orange) |
| `S` | File has staged changes | Info (blue/cyan) |
| `U` | File has unmerged conflicts | Error (red) |

Files with both staged and unstaged changes show both indicators: `S M`.

Parent directories show indicators when any descendant file has changes, even if the directory is collapsed.

## Usage

1. **Open the browser**: `:Tbrow` — git status indicators appear automatically.
2. **Refresh**: Press `<C-l>` to refresh the tree and git status.
3. **Auto-update**: Git status refreshes automatically when you save a file in any buffer.
4. **Non-git projects**: No indicators appear, and no errors are shown.

## Customizing Highlight Groups

The following highlight groups control git status indicator colors:

```lua
-- In your init.lua (after colorscheme is loaded):
vim.api.nvim_set_hl(0, "TbrowGitUnstaged", { fg = "#e0af68" })  -- custom yellow
vim.api.nvim_set_hl(0, "TbrowGitStaged", { fg = "#7dcfff" })    -- custom blue
vim.api.nvim_set_hl(0, "TbrowGitUnmerged", { fg = "#f7768e" })  -- custom red
```

By default, these groups are linked to `DiagnosticWarn`, `DiagnosticInfo`, and `DiagnosticError` respectively, so they match your colorscheme's diagnostic colors.

## Example Display

```
 lua/
   tbrow.lua          M
   model/
     state.lua     S M
     gitstatus.lua    S
   view/
     diagnostic.lua
```

In this example:
- `tbrow.lua` has unstaged changes
- `state.lua` has both staged and unstaged changes
- `gitstatus.lua` has staged changes
- `diagnostic.lua` is clean (no indicator)
- `model/` and `lua/` directories would also show indicators (propagated from children)
