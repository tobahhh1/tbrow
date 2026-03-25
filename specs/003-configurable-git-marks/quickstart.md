# Quickstart: Configurable Git Marks

**Feature**: 003-configurable-git-marks  
**Date**: 2026-03-25

## What This Feature Does

Extends tbrow's git status display with:
1. A new **untracked file** indicator (files not yet tracked by git)
2. Updated **default colors** matching git conventions (green/orange/red)
3. Full **configurability** of mark text and colors through `setup()`

## Default Behavior (No Configuration Needed)

Out of the box, the file browser shows four git status marks:

| Mark | Meaning | Color |
| ---- | ------- | ----- |
| `S` | Staged for commit | Green |
| `M` | Modified (unstaged) | Dark orange |
| `?` | Untracked (new file) | Dark orange |
| `U` | Unmerged (conflict) | Red |

## Customizing Marks

Pass a `git_marks` table to `setup()`:

```lua
require("tbrow"):setup({
  git_marks = {
    staged    = { text = " S", hl = { fg = "#608b4e" } },
    unstaged  = { text = " M", hl = { fg = "#d7875f" } },
    untracked = { text = " ?", hl = { fg = "#d7875f" } },
    unmerged  = { text = " U", hl = { fg = "#f44747" } },
  }
})
```

### Partial Overrides

Only specify what you want to change. Unspecified keys keep their defaults:

```lua
require("tbrow"):setup({
  git_marks = {
    staged = { text = " ✓" },              -- custom text, default color
    untracked = { hl = { fg = "#ffff00" } }, -- default text, custom color
  }
})
```

### Disabling a Mark

Set text to empty string to hide a specific mark type:

```lua
require("tbrow"):setup({
  git_marks = {
    untracked = { text = "" },  -- hide untracked marks
  }
})
```

### Advanced Highlight Options

The `hl` table accepts any valid `nvim_set_hl` attributes:

```lua
require("tbrow"):setup({
  git_marks = {
    staged = { hl = { fg = "#00ff00", bold = true } },
    unmerged = { hl = { fg = "#ff0000", bg = "#330000", underline = true } },
  }
})
```

### Using Highlight Group Links

Link to existing highlight groups instead of specifying colors:

```lua
require("tbrow"):setup({
  git_marks = {
    staged = { hl = { link = "DiffAdd" } },
    unmerged = { hl = { link = "DiffDelete" } },
  }
})
```

## Highlight Groups

The following highlight groups are defined with `default = true` and can also be overridden directly:

- `TbrowGitStaged` — staged mark color
- `TbrowGitUnstaged` — modified/unstaged mark color
- `TbrowGitUntracked` — untracked mark color
- `TbrowGitUnmerged` — unmerged/conflict mark color

## Files Changed

| File | Layer | Change |
| ---- | ----- | ------ |
| `lua/model/gitstatus.lua` | Model | Add `untracked` field to `GitStatusStore`; add `git ls-files` shell-out |
| `lua/view/gitstatus.lua` | View | Add `TbrowGitUntracked` highlight group; read config from `vim.g.tbrow_git_marks`; update default colors; add untracked to render loop |
| `lua/tbrow.lua` | Entry | Accept `git_marks` option in `setup()`; store in `vim.g.tbrow_git_marks` |
