# Implementation Plan: File Browser

**Branch**: `001-file-browser` | **Date**: 2026-03-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-file-browser/spec.md`

## Summary

Build a Neovim file browser plugin (`tbrow`) that renders directory trees inside standard Neovim buffers, using pure Lua and the Neovim API. The plugin follows an MVC architecture with immutable state, preserves all non-editing Vim functionality in the browser buffer, and exposes a Lua API for extensibility. The codebase already implements the majority of specified features (FR-001 through FR-021). Remaining work covers: multi-instance independence (FR-012), hidden file toggling (FR-023), primary/secondary open action alignment (FR-005/005a), and a test harness.

## Technical Context

**Language/Version**: Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9
**Primary Dependencies**: None beyond Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.loop`). Shell-outs to `ls` (filesystem) and `git` (status detection).
**Storage**: N/A — reads local filesystem only, no persistence layer
**Testing**: Neovim headless mode (`nvim --headless -u NONE`) with busted or a minimal custom harness. No test framework exists yet.
**Target Platform**: Any OS running Neovim ≥ 0.9
**Project Type**: Neovim plugin (library)
**Performance Goals**: < 1 second render for 500 entries (SC-003); < 100ms debounce for diagnostic updates; < 5 second end-to-end file open workflow (SC-001)
**Constraints**: Zero external runtime dependencies; single permitted global (`TbrowBufnrToInstance`); stack-based tree traversal only (no recursion); buffer must be `readonly`, `nomodifiable`, `buftype=nofile`, `filetype=tbrow`
**Scale/Scope**: Typical projects under 1,000 files; browser renders one directory tree per instance

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. MVC Separation | ✅ Pass | All new features map cleanly to existing layers: hidden-file toggle is model state + view re-render; multi-instance is controller/registry; API additions go in `lua/api/`. No cross-layer violations. |
| II. Immutable State | ✅ Pass | Hidden-file visibility becomes a field on ModelState; toggling returns a new ModelState. Multi-instance state is already per-bufnr in the registry. No direct mutation introduced. |
| III. Native Buffer Citizenship | ✅ Pass | FR-002 explicitly requires all non-editing Vim features work as-is. FR-005b prohibits extra built-in open behaviors. The hidden-file toggle and refresh keymaps (`<C-l>`, new toggle key) do not shadow any default Vim motion. |
| IV. API-First Surface | ✅ Pass | FR-012–FR-017 require Lua API exposure. All new capabilities (open in window, toggle hidden, refresh) will have corresponding API functions returning plain Lua types. |

**Architecture Constraints Check**:
- Language: Lua ✅
- Dependencies: None beyond Neovim stdlib ✅
- Global state: Only `TbrowBufnrToInstance` ✅
- Rendering: Stack-based traversal ✅
- Performance: Debounced diagnostics ✅

**Gate result: PASS** — No violations. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-file-browser/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Lua API contracts)
│   └── lua-api.md       # Public Lua API surface
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lua/
├── tbrow.lua               # Entry point, setup, keymaps, public re-exports
├── api/
│   └── file.lua            # Public API: file_under_cursor, directory_under_cursor
├── controller/
│   ├── actions.lua          # User actions: expand, collapse, toggle, open
│   └── initialize.lua       # Buffer creation, instance init, window targeting
├── model/
│   ├── diagnostic.lua       # DiagnosticStore, severity lookup/propagation
│   ├── filegraph.lua        # FileGraph node (immutable tree with structural sharing)
│   ├── filemetadata.lua     # FileMetadata (diagnostic level, git statuses)
│   ├── gitstatus.lua        # Git status cache (unstaged, staged, unmerged)
│   ├── populatechildren.lua # Directory expand/collapse, tree refresh
│   └── state.lua            # ModelState container (root, diagnostics, show_hidden)
├── view/
│   ├── diagnostic.lua       # Diagnostic extmark rendering
│   ├── drawfilesystem.lua   # Main tree renderer (stack-based traversal)
│   ├── fileatposition.lua   # Bidirectional line ↔ filepath mapping
│   ├── icons.lua            # Icon definitions, extension lookup, user overrides
│   ├── state.lua            # ViewState container (position mappings)
│   └── writetobuf.lua       # Guarded buffer write (unlock → write → re-lock)
└── utils/
    ├── debounce.lua         # Timer-based debounce for autocmds
    └── path.lua             # Path utilities (is_directory, split, iterate, extension)
```

**Structure Decision**: The existing `lua/` directory structure follows the MVC + API + Utils layering defined by the constitution. No structural changes are needed. All new functionality fits into existing modules or minor additions within them.

## Complexity Tracking

No constitution violations to justify — all gates pass cleanly.

### Post-Design Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. MVC Separation | ✅ Pass | `show_hidden` field lives in ModelState (model layer). Filtering hidden files during render is a view concern delegated to `drawfilesystem.lua`. Toggle action in controller. API in `lua/api/`. |
| II. Immutable State | ✅ Pass | `withHiddenToggled()` returns new ModelState. No mutation of existing state objects. |
| III. Native Buffer Citizenship | ✅ Pass | New toggle keymap will use a key that doesn't conflict with Vim motions (e.g., `gh` — "go hidden"). Confirmed: `gh` is not a default Vim motion in normal mode. |
| IV. API-First Surface | ✅ Pass | `open_in_win(winnr)` added to public API. `toggle_hidden()` accessible programmatically. Return types are plain Lua types. |

**Post-design gate: PASS**
