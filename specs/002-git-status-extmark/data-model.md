# Data Model: Git Status Extmark in File Browser

**Branch**: `002-git-status-extmark` | **Date**: 2026-03-25

## New Entities

### GitStatusStore

Cached lookup from file path to set membership for each git status type. Analogous to `DiagnosticStore`.

| Field | Type | Description |
|-------|------|-------------|
| `unstaged` | `table<string, boolean>` | Set of absolute paths with unstaged changes (includes ancestor directories) |
| `staged` | `table<string, boolean>` | Set of absolute paths with staged changes (includes ancestor directories) |
| `unmerged` | `table<string, boolean>` | Set of absolute paths with unmerged/conflict changes (includes ancestor directories) |

**Identity**: One `GitStatusStore` per `ModelState` instance.

**Construction**: Built by a factory function that shells out to `git diff --name-only` (three variants), converts relative paths to absolute, and propagates each path to all ancestor directories.

**State transitions** (all produce new instances):
- `GitStatusStore:refreshed()` → new `GitStatusStore` with fresh data from git commands
- `GitStatusStore:new({unstaged={}, staged={}, unmerged={}})` → empty store (for non-git projects)

## Modified Entities

### ModelState (updated)

Top-level container for all model-layer state. **New field: `git_status_store`**.

| Field | Type | Description |
|-------|------|-------------|
| `root` | `FileGraph` | Root node of the file tree |
| `diagnostic_store` | `DiagnosticStore` | Cached diagnostic severity lookup |
| `show_hidden` | `boolean` | Whether hidden files (dotfiles) are visible |
| `git_status_store` | `GitStatusStore` | Cached git status sets (unstaged, staged, unmerged) |

**New state transition**:
- `withGitStatusRefreshed()` → new ModelState with fresh `GitStatusStore`, all other fields preserved

### FileMetadata (clarified)

Already defined in `model/filemetadata.lua` with a `git_statuses` field. This entity is not currently used in rendering. For this feature, git status is read directly from `GitStatusStore` during rendering (keyed by file path), so `FileMetadata` remains unused. It may be used in a future refactor to aggregate per-file metadata.

## Unchanged Entities

These entities from the 001 data model are unaffected:

- **FileGraph**: Tree structure unchanged. Git status is orthogonal to tree structure.
- **ViewState**: Position mappings unchanged. Git status renders as virtual text (no column shifts).
- **DiagnosticStore**: Unchanged. Diagnostics and git status are independent.
- **BrowserInstance**: Registry entry structure unchanged (`{model_state, view_state}`). The `model_state` now carries `git_status_store` but the registry shape is the same.
- **IconMapping**: File icons unchanged. Git status uses separate symbols, not file icons.

## Relationships

```
ModelState
├── root: FileGraph (unchanged)
├── diagnostic_store: DiagnosticStore (unchanged)
├── show_hidden: boolean (unchanged)
└── git_status_store: GitStatusStore (NEW)
      ├── unstaged: set<absolute_path>
      ├── staged: set<absolute_path>
      └── unmerged: set<absolute_path>
```

**Render pipeline data flow**:
```
ModelState
  → draw_filesystem() builds lines + ViewState
    → draw_diagnostics(view_state, model_state, bufnr)
      reads: model_state.diagnostic_store
      renders: underline extmarks + diagnostic virtual text
      → draw_git_status(view_state, model_state, bufnr)
        reads: model_state.git_status_store
        renders: git status virtual text extmarks
```

## Validation Rules

- `GitStatusStore` sets contain only normalized absolute paths (via `vim.fs.normalize`)
- Directory paths in `GitStatusStore` sets end with `/` (from `get_all_roots()`)
- `GitStatusStore` fields default to empty tables `{}` when not in a git repo
- `ModelState.git_status_store` MUST NOT be `nil` — use an empty `GitStatusStore` for non-git projects
- When `is_git_repo()` returns false, all three sets MUST be empty (no shell errors propagate)

## Git Status Display Mapping

| Git State | Symbol | Highlight Group | Linked To |
|-----------|--------|----------------|-----------|
| Unstaged | `M` | `TbrowGitUnstaged` | `DiagnosticWarn` |
| Staged | `S` | `TbrowGitStaged` | `DiagnosticInfo` |
| Unmerged | `U` | `TbrowGitUnmerged` | `DiagnosticError` |

These highlight groups are defined with `default = true`, allowing user overrides via their colorscheme or `init.lua`.
