# Research: Git Status Extmark in File Browser

**Branch**: `002-git-status-extmark` | **Date**: 2026-03-25

## R1: GitStatusStore Integration into ModelState

**Decision**: Promote the existing `model/gitstatus.lua` singleton into a `GitStatusStore` class that lives as a field on `ModelState`, following the same pattern as `DiagnosticStore`.

**Rationale**: The constitution requires immutable state (Principle II). Currently `gitstatus.lua` exports a mutable singleton (`gitStore`) with a `refresh_git_cache()` method that mutates `self.git_cache` in place. This violates immutable state. By creating a `GitStatusStore` class with a constructor that takes the three cache sets, and a factory function `GitStatusStore:refreshed()` that returns a new instance, the git status data flows through `ModelState` immutably — just like diagnostics.

**Alternatives considered**:
- **Keep singleton, read-only access from view**: The view would call `gitStore.git_cache` directly during render. Rejected because it introduces a model → view dependency (view reads model singleton) that bypasses ModelState, making state transitions unpredictable and violating Principle II.
- **Store git status on FileGraph nodes**: Each `FileGraph` node would carry its own git status. Rejected because git status is orthogonal to tree structure — it changes independently when the user stages/unstages files without the tree changing. Coupling them would force unnecessary tree rebuilds.

## R2: Git Status Rendering Approach

**Decision**: Create a new `view/gitstatus.lua` module that renders git status indicators as virtual text extmarks, using a dedicated namespace. The renderer is called after `draw_diagnostics()` in the draw pipeline, so git status icons appear after diagnostic icons on the same line.

**Rationale**: The diagnostic renderer (`view/diagnostic.lua`) already establishes the pattern: a dedicated namespace, virtual text appended at end of line, and a draw function that accepts `(view_state, model_state, bufnr)` and returns `view_state`. Following this pattern means git status rendering is:
- Independently clearable (own namespace)
- Composable with diagnostics (both append virtual text)
- Consistent with the existing codebase conventions

The render order (diagnostics first, git status second) means diagnostic icons appear closer to the filename and git status icons appear further right. This matches the user's request for git status "next to the diagnostic extmark."

**Alternatives considered**:
- **Merge into diagnostic renderer**: Add git status rendering inside `view/diagnostic.lua`. Rejected because diagnostics and git status are independent concerns with different refresh triggers. Merging them violates single responsibility and would complicate independent refresh.
- **Inline in drawfilesystem**: Add git status characters directly into the line text (not as extmarks). Rejected because this would shift column positions, break the position mappings in ViewState, and make it harder to update git status independently of the full tree re-render.

## R3: Git Status Symbols and Highlight Groups

**Decision**: Use distinct Unicode symbols for each git status type, with dedicated highlight groups that integrate with the user's colorscheme:

| Status | Symbol | Highlight Group | Rationale |
|--------|--------|----------------|-----------|
| Unstaged | `M` | `TbrowGitUnstaged` (linked to `DiagnosticWarn`) | `M` is the standard git shorthand for modified. Warning color signals "needs attention." |
| Staged | `S` | `TbrowGitStaged` (linked to `DiagnosticInfo`) | `S` for staged. Info color signals "ready / acknowledged." |
| Unmerged | `U` | `TbrowGitUnmerged` (linked to `DiagnosticError`) | `U` is the standard git shorthand for unmerged. Error color signals "conflict / action required." |

Highlight groups are created via `vim.api.nvim_set_hl(0, ...)` with `default = true` so users can override them. Linking to existing `Diagnostic*` groups ensures they look reasonable in any colorscheme without custom configuration.

**Rationale**: Using single-letter symbols (`M`, `S`, `U`) satisfies SC-002 (distinguishable without color alone — each has a different letter). Linking to diagnostic highlight groups ensures visual consistency with the existing diagnostic indicators and works out-of-the-box with all colorschemes.

**Alternatives considered**:
- **Nerd Font icons**: Icons like `●`, `✓`, `✗`. Rejected because they require a Nerd Font and some (like filled circles) are only distinguishable by color, failing SC-002.
- **Reuse `DiffAdd`/`DiffChange`/`DiffDelete` groups**: Standard Vim diff highlights. Rejected because they're designed for diff views (background colors) and may not render well as virtual text foreground colors.

## R4: Git Status Refresh Triggers

**Decision**: Git status refreshes on two triggers:
1. **Manual refresh** (`<C-l>`): The existing `refresh_filesystem()` function already re-renders the full tree. Adding `withGitStatusRefreshed()` to this flow means git status updates on manual refresh with no new keymaps.
2. **`BufWritePost` autocommand**: When any buffer is written, git status is recalculated and re-rendered (debounced at 200ms). This covers the most common case of a developer saving a file and expecting the browser to reflect the change.

**Rationale**: `BufWritePost` is the most reliable editor event that correlates with git status changes — writing a file creates an unstaged change, and writing after a stage operation may indicate workflow progress. Combined with manual `<C-l>` for edge cases (staging from terminal, rebasing), this covers the primary use cases without filesystem watchers.

The 200ms debounce prevents rapid-fire writes from causing excessive git shell-outs, satisfying the edge case in the spec about rapid git status changes.

**Alternatives considered**:
- **`FocusGained` autocommand**: Refresh when Neovim regains focus. Rejected as primary trigger because it doesn't fire during normal editing within Neovim (e.g., editing in a split). Good as a supplementary trigger but not essential for MVP.
- **Filesystem watcher (`vim.loop.fs_event`)**: Watch `.git/index` for changes. Rejected because the spec explicitly states filesystem watchers are out of scope, and `vim.loop.fs_event` behavior varies across platforms.
- **Timer-based polling**: Refresh every N seconds. Rejected because it wastes resources when nothing has changed and adds latency when something has.

## R5: Handling Files with Both Staged and Unstaged Changes

**Decision**: When a file has both staged and unstaged changes, display both indicators on the same line. The git status renderer appends one virtual text chunk per active status, so a file with staged + unstaged changes shows `S M` (two separate virtual text entries).

**Rationale**: FR-012 explicitly requires both indicators. The extmark virtual text API supports multiple `virt_text` entries on the same line (each `nvim_buf_set_extmark` call with `virt_text` appends independently when using different extmark IDs within the same namespace). This is straightforward to implement and visually clear.

**Alternatives considered**:
- **Combined symbol** (e.g., `SM`): A single merged indicator. Rejected because it's less visually clear and harder to scan than two distinct, color-coded symbols.
- **Priority-based single indicator**: Show only the "most important" status. Rejected because it violates FR-012 and hides information the user needs to make workflow decisions.
