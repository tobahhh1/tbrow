# Data Model: File Browser

**Branch**: `001-file-browser` | **Date**: 2026-03-25

## Entities

### FileGraph

Represents a single node in the file tree. Directories may have children; files are leaf nodes.

| Field | Type | Description |
|-------|------|-------------|
| `absolute_filepath` | `string` | Full path to the file or directory. Directories end with `/`. |
| `children` | `table<string, FileGraph> \| nil` | Child nodes keyed by filename. `nil` = collapsed, non-nil = expanded. |

**Identity**: Unique by `absolute_filepath` within a single tree instance.

**State transitions**:
- Collapsed → Expanded: `children` set to populated table via `expand_children()`
- Expanded → Collapsed: `children` set to `nil` via `with_file_collapsed()`
- Replacement: `withNodeAtPathReplaced()` creates new root with structural sharing along the modified path

### ModelState

Top-level container for all model-layer state associated with one browser instance.

| Field | Type | Description |
|-------|------|-------------|
| `root` | `FileGraph` | Root node of the file tree |
| `diagnostic_store` | `DiagnosticStore` | Cached diagnostic severity lookup |
| `show_hidden` | `boolean` | Whether hidden files (dotfiles) are visible. Default: `true`. |

**Identity**: One ModelState per browser buffer, stored in `TbrowBufnrToInstance[bufnr].model_state`.

**State transitions** (all return new ModelState):
- `withDiagnosticsRefreshed()` → new ModelState with fresh diagnostic cache
- `withHiddenToggled()` → new ModelState with `show_hidden` inverted
- `with_file_expanded(state, path)` → new ModelState with directory expanded
- `with_file_collapsed(state, path)` → new ModelState with directory collapsed
- `with_root_refreshed(state)` → new ModelState with tree re-read from disk

### ViewState

Rendering state that maps buffer lines to file paths and vice versa.

| Field | Type | Description |
|-------|------|-------------|
| `line_num_to_absolute_filepath` | `table<integer, string>` | Line number → absolute file path |
| `absolute_filepath_to_first_position` | `table<string, {row, col}>` | File path → first character position (for cursor placement) |
| `absolute_filepath_to_last_position` | `table<string, {row, col}>` | File path → last character position (for diagnostic underline extent) |

**Identity**: One ViewState per browser buffer, stored in `TbrowBufnrToInstance[bufnr].view_state`.

**Lifecycle**: Rebuilt on every render pass. Not mutated after creation.

### DiagnosticStore

Cached lookup from file path to maximum diagnostic severity.

| Field | Type | Description |
|-------|------|-------------|
| `max_diag_severity_by_file_lu` | `table<string, vim.diagnostic.Severity>` | Absolute path → severity (ERROR < WARN < INFO < HINT, lower = more severe) |

**Construction**: Built by `get_max_diag_severity_by_file_lu()` which walks all diagnostics and propagates severity to parent directories.

### FileMetadata

Per-file diagnostic and git information (used during rendering).

| Field | Type | Description |
|-------|------|-------------|
| `diagnostic_level` | `vim.diagnostic.Severity \| nil` | Maximum diagnostic severity for this file |
| `git_statuses` | `GitStatus[]` | List of git statuses (unstaged, staged, unmerged) |

### GitStore

Singleton cache for git status across the working tree.

| Field | Type | Description |
|-------|------|-------------|
| `git_cache.unstaged` | `table<string, boolean>` | Set of paths with unstaged changes (includes parent dirs) |
| `git_cache.staged` | `table<string, boolean>` | Set of paths with staged changes (includes parent dirs) |
| `git_cache.unmerged` | `table<string, boolean>` | Set of paths with unmerged changes (includes parent dirs) |

**Refresh**: `refresh_git_cache()` re-runs `git diff` commands and rebuilds all three sets.

### IconMapping

Association between file type and visual representation.

| Field | Type | Description |
|-------|------|-------------|
| key | `string` | File extension, full filename, or special key (`directory`, `directory_expanded`, `file`) |
| icon | `string` | Unicode character (typically Nerd Font glyph) |
| highlight | `string` | Neovim highlight group name |

**Lookup priority**: extension → filename → `"file"` default. User overrides via `vim.g.tbrow_icons`.

### BrowserInstance (Registry Entry)

Per-buffer entry in the global `TbrowBufnrToInstance` registry.

| Field | Type | Description |
|-------|------|-------------|
| `model_state` | `ModelState` | Current model state for this instance |
| `view_state` | `ViewState` | Current view state for this instance |

**Identity**: Keyed by `bufnr` (Neovim buffer number). One entry per browser buffer.

## Relationships

```
TbrowBufnrToInstance (global registry)
  └── [bufnr] → BrowserInstance
                   ├── model_state: ModelState
                   │     ├── root: FileGraph (tree structure)
                   │     │     └── children: table<string, FileGraph> (recursive)
                   │     ├── diagnostic_store: DiagnosticStore
                   │     └── show_hidden: boolean
                   └── view_state: ViewState
                         ├── line_num → filepath
                         ├── filepath → first_position
                         └── filepath → last_position

GitStore (singleton, refreshed on demand)
  └── git_cache: {unstaged, staged, unmerged} sets

IconMapping (static + user overrides via vim.g.tbrow_icons)
  └── extension/filename → {icon, highlight}
```

## Validation Rules

- `FileGraph.absolute_filepath` for directories MUST end with `/`
- `FileGraph.children` keys MUST match the filename portion of the child's `absolute_filepath`
- `ModelState.show_hidden` defaults to `true` (hidden files visible)
- `DiagnosticStore` severity values use Neovim's ordering: ERROR(1) < WARN(2) < INFO(3) < HINT(4)
- `ViewState` mappings MUST be consistent: every line number maps to a filepath, and every filepath maps back to a valid line position
- `TbrowBufnrToInstance` entries MUST be replaced atomically (both model_state and view_state together)
