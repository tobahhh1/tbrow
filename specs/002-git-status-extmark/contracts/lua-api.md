# Lua API Contract: Git Status Extmark

**Branch**: `002-git-status-extmark` | **Date**: 2026-03-25

This document describes the API surface changes for the git status extmark feature. This feature adds **no new public API functions**. All git status functionality is internal to the render pipeline and triggered automatically.

## No New Public Functions

Git status indicators are a visual enhancement that renders automatically when the file browser draws. The existing API functions continue to work unchanged:

| Existing Function | Impact |
|-------------------|--------|
| `tbrow.api.file.file_under_cursor(winnr)` | No change — returns file path as before |
| `tbrow.api.file.directory_under_cursor(winnr)` | No change — returns directory path as before |
| `tbrow.api.file.open_in_win(path, winnr)` | No change — opens browser with git status included |
| `tbrow.api.file.refresh(winnr)` | No change — now also refreshes git status as part of the re-render |
| `tbrow.api.file.toggle_hidden(winnr)` | No change — re-render includes git status |

## Highlight Groups (User-Customizable)

The following highlight groups are created with `default = true` and can be overridden by users:

| Group | Default Link | Purpose |
|-------|-------------|---------|
| `TbrowGitUnstaged` | `DiagnosticWarn` | Color for unstaged change indicator (`M`) |
| `TbrowGitStaged` | `DiagnosticInfo` | Color for staged change indicator (`S`) |
| `TbrowGitUnmerged` | `DiagnosticError` | Color for unmerged/conflict indicator (`U`) |

**Override example**:
```lua
vim.api.nvim_set_hl(0, "TbrowGitUnstaged", { fg = "#e0af68" })
```

## Behavioral Changes to Existing Features

### Manual Refresh (`<C-l>`)

Previously refreshed only the filesystem tree and diagnostics. Now also refreshes git status data before re-rendering.

### Automatic Refresh

A new `BufWritePost` autocommand (buffer-independent, debounced at 200ms) triggers git status recalculation and re-rendering of the git status indicators. This does not trigger a full tree re-render — only the git status extmarks are updated.

### Instance Initialization

New browser instances now include a `git_status_store` in their initial `ModelState`. When opened in a git repository, git status is populated immediately. When opened outside a git repository, an empty store is used (no errors, no indicators).

## Conventions

- No new public API functions are introduced.
- Highlight groups follow the `Tbrow*` naming convention.
- Git status rendering follows the same pattern as diagnostic rendering (virtual text extmarks, dedicated namespace, own draw function).
- All changes are backward-compatible — existing configurations and API usage continue to work without modification.
