# Implementation Plan: Configurable Git Marks

**Branch**: `003-configurable-git-marks` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-configurable-git-marks/spec.md`

## Summary

Extend the git status display system to support a fourth status type (untracked files), update default highlight colors to conventional git semantics (green/staged, dark orange/modified+untracked, red/unmerged), and make both the mark text and colors user-configurable through the existing `setup()` options pattern.

## Technical Context

**Language/Version**: Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9  
**Primary Dependencies**: Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.fs`)  
**Storage**: N/A  
**Testing**: No automated test framework in use; manual verification via file browser  
**Target Platform**: Neovim ≥ 0.9 on any OS  
**Project Type**: Neovim plugin (Lua library)  
**Performance Goals**: Git status rendering must not introduce perceptible delay when navigating; debounced refresh at 200ms  
**Constraints**: No external dependencies beyond Neovim stdlib; shell-outs to `git` are acceptable in model boundary functions only  
**Scale/Scope**: Projects with up to 500 changed files; 4 git status types

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check

| Principle | Status | Notes |
| --------- | ------ | ----- |
| **I. MVC Separation** | ✅ Pass | Model changes (new `untracked` field, new git command) stay in `lua/model/gitstatus.lua`. View changes (new highlight group, config reading) stay in `lua/view/gitstatus.lua`. Configuration is set in `lua/tbrow.lua` (controller/API layer) via `setup()`. No cross-layer violations. |
| **II. Immutable State** | ✅ Pass | `GitStatusStore:refreshed()` already returns a new object. Adding `untracked` field follows the same pattern. No mutation introduced. |
| **III. Native Buffer Citizenship** | ✅ Pass | No new keymaps added. Only extmark rendering changes. All Vim motions preserved. |
| **IV. API-First Surface** | ✅ Pass | Configuration is exposed via `setup()` opts, consistent with existing pattern. No new public API functions needed. |
| **Architecture Constraints** | ✅ Pass | No new dependencies. Shell-out (`git ls-files`) is in model layer. Only permitted global `TbrowBufnrToInstance` unchanged; config uses `vim.g` consistent with existing options. |

### Post-Design Check

| Principle | Status | Notes |
| --------- | ------ | ----- |
| **I. MVC Separation** | ✅ Pass | Model: `gitstatus.lua` adds `untracked` set + `git ls-files` shell-out. View: `gitstatus.lua` reads config from `vim.g`, defines highlight groups, renders extmarks. Controller: `tbrow.lua` stores config in `vim.g` via `setup()`. No cross-layer imports added. |
| **II. Immutable State** | ✅ Pass | `GitStatusStore` gains `untracked` field; `refreshed()` returns new instance with all four sets. No mutation. |
| **III. Native Buffer Citizenship** | ✅ Pass | No keymaps touched. |
| **IV. API-First Surface** | ✅ Pass | No new public API functions. Configuration via `setup()` opts is the established pattern. |

## Project Structure

### Documentation (this feature)

```text
specs/003-configurable-git-marks/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── lua-api.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lua/
├── model/
│   ├── gitstatus.lua    # Add untracked field + git ls-files shell-out
│   └── state.lua        # No changes (GitStatusStore type annotation updated)
├── view/
│   └── gitstatus.lua    # New highlight groups, config reading, untracked rendering
└── tbrow.lua            # Add git_marks option to setup()
```

**Structure Decision**: Existing MVC layout is used. Changes touch 3 files across model and view layers, plus the top-level setup entry point. No new files or directories in source code.
