# Lua API Contract: Configurable Git Marks

**Feature**: 003-configurable-git-marks  
**Date**: 2026-03-25

## Public API Changes

### `setup()` Options — New Field: `git_marks`

**No new public API functions are added.** Configuration is exposed through the existing `setup()` entry point.

#### New Option

```lua
require("tbrow"):setup({
  git_marks = {  -- optional, table or nil
    staged    = { text = " S", hl = { fg = "#608b4e" } },  -- optional
    unstaged  = { text = " M", hl = { fg = "#d7875f" } },  -- optional
    untracked = { text = " ?", hl = { fg = "#d7875f" } },  -- optional
    unmerged  = { text = " U", hl = { fg = "#f44747" } },  -- optional
  }
})
```

#### Type Contract

```
git_marks: table | nil
  [status_key]: table | nil     -- key is one of: "staged", "unstaged", "untracked", "unmerged"
    text: string | nil           -- mark symbol (default varies by status)
    hl:   table  | nil           -- highlight attributes table (passed to nvim_set_hl)
```

#### Behavior

- If `git_marks` is `nil` or omitted: all defaults are used.
- If `git_marks` is a table: each present key overrides that status's defaults. Absent keys retain defaults.
- If a status key is present but `text` is `nil`: default text is used for that status.
- If a status key is present but `hl` is `nil`: default highlight is used for that status.
- If `text` is `""` (empty string): that mark is effectively hidden (no virtual text rendered).
- The `hl` table is passed directly to `vim.api.nvim_set_hl(0, group_name, hl)`. Any valid `nvim_set_hl` attributes are accepted (`fg`, `bg`, `bold`, `italic`, `underline`, `link`, etc.).

#### Storage

Value stored as `vim.g.tbrow_git_marks` — consistent with `vim.g.tbrow_icons`, `vim.g.tbrow_indent_string`, etc.

## Highlight Groups

All groups defined with `default = true`, allowing colorschemes and users to override.

| Group Name | Default Attrs | Purpose |
| ---------- | ------------- | ------- |
| `TbrowGitStaged` | `{ fg = "#608b4e" }` | Staged file mark |
| `TbrowGitUnstaged` | `{ fg = "#d7875f" }` | Modified file mark |
| `TbrowGitUntracked` | `{ fg = "#d7875f" }` | Untracked file mark |
| `TbrowGitUnmerged` | `{ fg = "#f44747" }` | Unmerged/conflict file mark |

**Change from previous feature**: Groups previously used `link` to Diagnostic groups. Now use explicit `fg` values for correct git-conventional colors.

## Backward Compatibility

- `setup()` without `git_marks` behaves identically to before, except highlight defaults change from diagnostic links to explicit git-conventional colors.
- Existing user overrides of `TbrowGitStaged`, `TbrowGitUnstaged`, `TbrowGitUnmerged` via `nvim_set_hl` continue to work (groups are still `default = true`).
- New `TbrowGitUntracked` group is additive.
- The `setup()` `git_marks` option provides a more discoverable configuration path but does not replace direct highlight group customization.

## Internal Changes (Not Public API)

### Model Layer: `GitStatusStore`

- New field: `untracked: table<string, boolean>`
- New internal function: `git_untracked_files()` — shells out to `git ls-files --others --exclude-standard`
- `refreshed()` populates the `untracked` set using the same pipeline as other statuses

### View Layer: `draw_git_status()`

- `status_config` table gains a fourth entry for `untracked`
- At render time, text and highlight for each status are resolved by checking `vim.g.tbrow_git_marks` first, then falling back to `status_config` defaults
- Highlight groups are set up once at module load time, with `setup()` overrides applied when `git_marks` option is provided
