# Implementation Plan: Git Status Extmark in File Browser

**Branch**: `002-git-status-extmark` | **Date**: 2026-03-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-git-status-extmark/spec.md`

## Summary

Display git status indicators (unstaged, staged, unmerged) as virtual text extmarks at the end of each file entry line in the tbrow file browser, positioned adjacent to existing diagnostic extmarks. The implementation follows the established diagnostic rendering pattern: a model-layer store holds git status data, a view-layer renderer draws extmarks, and the controller wires refresh triggers. The existing `model/gitstatus.lua` singleton is promoted into a `GitStatusStore` on `ModelState`, following the immutable state principle.

## Technical Context

**Language/Version**: Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9  
**Primary Dependencies**: None beyond Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.loop`). Shell-outs to `git` for status detection.  
**Storage**: N/A — reads git index/working tree via shell commands  
**Testing**: Neovim headless mode (`nvim --headless -u NONE -l <test_file>`) with custom harness (from 001)  
**Target Platform**: Any OS running Neovim ≥ 0.9  
**Project Type**: Neovim plugin (library)  
**Performance Goals**: < 1 second render for 500 entries with git status; git refresh completes without perceptible editor blocking  
**Constraints**: Zero external runtime dependencies; single permitted global (`TbrowBufnrToInstance`); stack-based tree traversal only; debounced refresh for git status  
**Scale/Scope**: Typical projects under 1,000 files; up to 500 changed files per git status query

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. MVC Separation | ✅ Pass | Git status data lives in model layer (`model/gitstatus.lua` → `GitStatusStore`). Rendering lives in view layer (new `view/gitstatus.lua`). Refresh wiring lives in controller/entry point (`tbrow.lua`). No cross-layer violations. |
| II. Immutable State | ✅ Pass | `GitStatusStore` becomes a field on `ModelState`. New `withGitStatusRefreshed()` returns a new ModelState — same pattern as `withDiagnosticsRefreshed()`. No mutation of existing state objects. |
| III. Native Buffer Citizenship | ✅ Pass | No new keymaps are added. Git status renders as virtual text extmarks (non-intrusive). All Vim motions remain fully operational. Manual refresh via existing `<C-l>` already refreshes the tree. |
| IV. API-First Surface | ✅ Pass | No new public API functions required for this feature. Git status is a visual enhancement rendered automatically. The existing `refresh()` API will trigger git status refresh as part of the re-render cycle. |

**Architecture Constraints Check**:
- Language: Lua ✅
- Dependencies: None beyond Neovim stdlib + `git` shell-out (already used) ✅
- Global state: Only `TbrowBufnrToInstance` ✅
- Rendering: Stack-based traversal (unchanged) ✅
- Performance: Git status refresh will be debounced ✅

**Gate result: PASS** — No violations. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/002-git-status-extmark/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── lua-api.md       # Updated Lua API surface (no new public functions)
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lua/
├── tbrow.lua                    # Entry point — add git status refresh trigger + wiring
├── api/
│   └── file.lua                 # No changes needed
├── controller/
│   ├── actions.lua              # No changes needed
│   └── initialize.lua           # Initialize GitStatusStore in new instances
├── model/
│   ├── diagnostic.lua           # No changes needed
│   ├── filegraph.lua            # No changes needed
│   ├── filemetadata.lua         # No changes needed
│   ├── gitstatus.lua            # Refactor: extract GitStatusStore class, add constructor
│   ├── populatechildren.lua     # No changes needed
│   └── state.lua                # Add git_status_store field + withGitStatusRefreshed()
├── view/
│   ├── diagnostic.lua           # No changes needed
│   ├── drawfilesystem.lua       # Call git status renderer after diagnostics
│   ├── fileatposition.lua       # No changes needed
│   ├── gitstatus.lua            # NEW: git status extmark renderer
│   ├── icons.lua                # No changes needed
│   ├── state.lua                # No changes needed
│   └── writetobuf.lua           # No changes needed
└── utils/
    ├── debounce.lua             # No changes needed
    └── path.lua                 # No changes needed
```

**Structure Decision**: The existing `lua/` MVC structure is preserved. One new file (`view/gitstatus.lua`) is added for the git status renderer. All other changes are modifications to existing files within their correct layers.

## Complexity Tracking

No constitution violations to justify — all gates pass cleanly.

### Post-Design Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. MVC Separation | ✅ Pass | `GitStatusStore` in model layer. `view/gitstatus.lua` handles rendering. `tbrow.lua` wires triggers. `initialize.lua` constructs initial state. Clean layer boundaries. |
| II. Immutable State | ✅ Pass | `withGitStatusRefreshed()` returns new ModelState with fresh git data. Git cache sets are rebuilt on each refresh (not mutated). |
| III. Native Buffer Citizenship | ✅ Pass | No keymaps added or modified. Virtual text is non-intrusive. All motions preserved. |
| IV. API-First Surface | ✅ Pass | No new public API needed. Existing `refresh()` API naturally picks up git status through the re-render pipeline. |

**Post-design gate: PASS**
