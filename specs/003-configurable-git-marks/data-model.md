# Data Model: Configurable Git Marks

**Feature**: 003-configurable-git-marks  
**Date**: 2026-03-25

## Modified Entity: GitStatusStore

**File**: `lua/model/gitstatus.lua`

| Field | Type | Description |
| ----- | ---- | ----------- |
| `unstaged` | `table<string, boolean>` | Set of absolute paths with unstaged changes (includes ancestor directories) |
| `staged` | `table<string, boolean>` | Set of absolute paths with staged changes (includes ancestor directories) |
| `unmerged` | `table<string, boolean>` | Set of absolute paths with unmerged/conflict changes (includes ancestor directories) |
| `untracked` | `table<string, boolean>` | **NEW** — Set of absolute paths for files not tracked by git and not ignored (includes ancestor directories) |

**Construction**: The existing `refreshed()` method gains a fourth set built from `git ls-files --others --exclude-standard`. The output is processed through the same pipeline as the other statuses: `to_absolute_paths` → `map(get_all_roots, ...)` → `flatten` → `list_to_set`.

**Validation rules**:
- All sets contain only normalized absolute paths
- Directory paths end with `/`
- Sets default to `{}` when not in a git repo
- `untracked` set excludes files matched by `.gitignore` (enforced by `--exclude-standard`)

**Type annotation update**:

```lua
--- @class GitStatusStore
--- @field unstaged table<string, boolean>
--- @field staged table<string, boolean>
--- @field unmerged table<string, boolean>
--- @field untracked table<string, boolean>
```

## New Entity: Git Mark Default Configuration

**File**: `lua/view/gitstatus.lua` (internal to view layer)

Represents the default display settings for each git status type. Not a persisted data model — it is a compile-time constant in the view module.

| Status Key | Default Text | Default Highlight Name | Default Highlight Attrs |
| ---------- | ------------ | --------------------- | ---------------------- |
| `staged` | `" S"` | `TbrowGitStaged` | `{ fg = "#608b4e" }` |
| `unstaged` | `" M"` | `TbrowGitUnstaged` | `{ fg = "#d7875f" }` |
| `untracked` | `" ?"` | `TbrowGitUntracked` | `{ fg = "#d7875f" }` |
| `unmerged` | `" U"` | `TbrowGitUnmerged` | `{ fg = "#f44747" }` |

## New Entity: User Git Mark Configuration

**File**: Stored at `vim.g.tbrow_git_marks` (set by `setup()`)

An optional user-provided table that overrides defaults. Structure mirrors the defaults:

```
vim.g.tbrow_git_marks = {
  [status_key] = {
    text = string | nil,    -- overrides default mark text
    hl   = table  | nil,    -- overrides highlight attrs (passed to nvim_set_hl)
  }
}
```

**Merge behavior**: At render time, for each status key:
1. If `vim.g.tbrow_git_marks[key]` exists and has a `text` field → use that text
2. Otherwise → use default text from `status_config`
3. If `vim.g.tbrow_git_marks[key]` exists and has an `hl` field → apply those highlight attrs
4. Otherwise → use default highlight attrs

## Unchanged Entities

- **ModelState**: No structural change. The `git_status_store` field type annotation gains `untracked` via the updated `GitStatusStore` class, but the ModelState class itself and `withGitStatusRefreshed()` require no code changes beyond what the refreshed GitStatusStore provides.
- **ViewState**: No changes. Line-to-filepath mappings remain the same.
- **FileGraph**: No changes.
- **DiagnosticStore**: No changes.

## Render Pipeline Data Flow (Updated)

```
ModelState.git_status_store
  → GitStatusStore { unstaged, staged, unmerged, untracked }

vim.g.tbrow_git_marks (user overrides, may be nil)
  → merged with default status_config at render time

draw_git_status(view_state, model_state, bufnr)
  → for each line:
    → for each status in [staged, unstaged, untracked, unmerged]:
      → if file_path in git_store[status.key]:
        → resolve text (user override or default)
        → resolve highlight group (user override applied at setup or default)
        → append to virt_text
    → set extmark with virt_text at eol
```
