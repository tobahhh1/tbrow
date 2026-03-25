# Research: File Browser

**Branch**: `001-file-browser` | **Date**: 2026-03-25

## R1: Testing Strategy for Neovim Lua Plugins

**Decision**: Use Neovim headless mode with a minimal custom test harness.

**Rationale**: The constitution prohibits external runtime dependencies. While `busted` and `plenary.nvim` are popular in the Neovim plugin ecosystem, they introduce dependencies. A minimal harness using `nvim --headless -u NONE -l <test_file>` keeps the project self-contained and tests run in the actual Neovim environment where the plugin operates. Test files use plain Lua `assert()` calls with a thin wrapper for reporting.

**Alternatives considered**:
- **busted**: Full-featured Lua test framework. Rejected because it requires LuaRocks installation, adding friction and a dependency outside the Neovim stdlib. Could be adopted later if test complexity warrants it.
- **plenary.nvim**: Neovim-specific testing built on busted. Rejected because it adds a plugin dependency for testing, violating the spirit of zero external dependencies. Also couples tests to plenary's API surface.
- **mini.test**: Lightweight Neovim test framework. Rejected for same dependency reason, though it's the lightest option. Good fallback if custom harness proves insufficient.

## R2: Hidden File Toggle — State Management Approach

**Decision**: Add a `show_hidden` boolean field to `ModelState`. The `drawfilesystem` renderer filters entries where the filename starts with `.` when `show_hidden` is `false`. Toggle returns a new `ModelState` via `withHiddenToggled()`.

**Rationale**: Keeping visibility as model state (rather than view state) ensures that the API can query and set it programmatically. It follows the immutable state principle — toggling produces a new ModelState, which triggers a re-render. The renderer already iterates all children; adding a filter condition is O(1) per entry with no architectural changes.

**Alternatives considered**:
- **View-layer filtering**: Filter in `drawfilesystem` without model state tracking. Rejected because the API couldn't query or set hidden-file visibility, violating the API-First principle.
- **Separate filter state object**: A dedicated filter state alongside ModelState. Rejected as over-engineering for a single boolean; if more filters are added later, this could be revisited.

## R3: Multi-Instance Independence

**Decision**: The existing `TbrowBufnrToInstance` registry already supports multiple independent instances keyed by buffer number. Each buffer gets its own `{model_state, view_state}` pair. No architectural changes needed — the current design already satisfies FR-012.

**Rationale**: When `open_in_win()` is called for a new window, it creates a new buffer with `get_or_create_buf()`, initializes a fresh ModelState, and registers it in `TbrowBufnrToInstance[bufnr]`. Since each entry is keyed by buffer number and contains its own model/view state, instances are inherently independent. The `show_hidden` field (R2) will also be per-instance since it lives on ModelState.

**Alternatives considered**:
- **Shared state with per-instance overrides**: A single tree shared across instances with per-instance view overrides. Rejected because the spec explicitly requires independent tree state (expansion, collapse, hidden-file visibility) per instance. Shared state would violate this and add complexity.

## R4: Primary/Secondary Open Action Keymaps

**Decision**: `<CR>` remains the primary action (open in current window / toggle directory). `p` and `P` are secondary actions (open in previous window). The existing keymap assignments already match the spec after the clarification that primary = current window, secondary = previous window.

**Rationale**: The current `<CR>` binding already toggles directories and opens files in the current window (replacing the browser). The `p`/`P` bindings already open in the previous window. The only behavioral change needed: `<CR>` on a file should directly open it in the current window (currently it tries toggle first, then falls back to open). This should be made explicit rather than error-driven.

**Alternatives considered**:
- **Separate keymaps for toggle vs open**: Use `<CR>` only for open, a different key for toggle. Rejected because the current behavior (toggle on directory, open on file) is intuitive and matches user expectations from other file browsers.

## R5: Keymap for Hidden File Toggle

**Decision**: Use `gh` ("go hidden") as the keymap for toggling hidden file visibility.

**Rationale**: `gh` is not a default Vim normal-mode command (in Vim, `gh` enters Select mode, but Select mode is rarely used in Neovim and this binding is buffer-local). It's mnemonic ("go hidden" or "ghost"), follows the existing pattern of two-character action keys (`yd`, `yc`), and doesn't conflict with any navigation motion. The constitution requires confirming no default Vim motion is shadowed — `gh` shadows Select mode entry, but Select mode is not a navigation motion and is unused in the tbrow context.

**Alternatives considered**:
- **`.` (dot)**: Mnemonic for dotfiles. Rejected because `.` is the repeat-last-change command — a core Vim feature that must not be overridden per FR-002.
- **`H`**: Rejected because `H` moves cursor to top of screen — a navigation motion.
- **`<C-h>`**: Rejected because it may conflict with terminal backspace handling on some systems.
