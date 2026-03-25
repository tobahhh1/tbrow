# Tasks: Git Status Extmark in File Browser

**Input**: Design documents from `/specs/002-git-status-extmark/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/lua-api.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Refactor the model layer so git status data flows through ModelState immutably, following the DiagnosticStore pattern established in 001.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T001 Refactor lua/model/gitstatus.lua — Replace the mutable singleton pattern with a `GitStatusStore` class. Create a local `prototype` table with fields `unstaged` (table<string, boolean>), `staged` (table<string, boolean>), `unmerged` (table<string, boolean>), defaulting to empty tables. Add a `new(o)` constructor following the existing metatable pattern (see `DiagnosticStore:new` in lua/model/diagnostic.lua). Add a `refreshed()` class method that creates and returns a new `GitStatusStore` instance by calling the existing `git_unstaged_changes()`, `git_staged_changes()`, `git_unmerged_changes()` helper functions, converting results through `get_all_roots` + `flatten` + `map` + `list_to_set` (the existing pipeline). Keep all helper functions (`split`, `to_absolute_paths`, `is_git_repo`, `git_unstaged_changes`, `git_staged_changes`, `git_unmerged_changes`, `list_to_set`, `get_all_roots`, `map`, `flatten`) as local functions. Export `M.GitStatusStore = prototype` and remove the old `gitStore` singleton export. The `refreshed()` method must return a store with empty sets when `is_git_repo()` returns false.

- [ ] T002 Update lua/model/state.lua — Add `git_status_store` field to the `ModelState` prototype (require `GitStatusStore` from `model.gitstatus`). Add a `withGitStatusRefreshed()` method that returns a new `ModelState` with a fresh `GitStatusStore` (calling `GitStatusStore:refreshed()`), preserving `root`, `show_hidden`, and `diagnostic_store`. Update `withDiagnosticsRefreshed()` to carry forward `git_status_store` in the new ModelState it returns. Update `withHiddenToggled()` to carry forward `git_status_store` in the new ModelState it returns. This follows the immutable state pattern per Constitution Principle II.

**Checkpoint**: Model layer ready — GitStatusStore class exists and ModelState can carry and refresh git status data.

---

## Phase 2: User Story 1 — See Git Status at a Glance (Priority: P1) 🎯 MVP

**Goal**: Files with unstaged, staged, or unmerged git changes display a visual indicator (M/S/U) at the end of their line in the file browser, adjacent to any diagnostic indicator.

**Independent Test**: Modify a file, stage a file, and create a merge conflict. Open the file browser and verify each status indicator appears next to the correct file entry. Verify files with no changes show no indicator. Verify both diagnostic and git status indicators appear on the same line when applicable.

### Implementation for User Story 1

- [ ] T003 [P] [US1] Create lua/view/gitstatus.lua — New file implementing the git status extmark renderer. Create a namespace `tbrow_git_status_ns` via `vim.api.nvim_create_namespace("tbrow_git_status_ns")`. Define three highlight groups using `vim.api.nvim_set_hl(0, name, opts)` with `default = true`: `TbrowGitUnstaged` linked to `DiagnosticWarn`, `TbrowGitStaged` linked to `DiagnosticInfo`, `TbrowGitUnmerged` linked to `DiagnosticError`. Create a local `status_config` table mapping each status type to its symbol and highlight group name: `{key="staged", symbol="S", hl="TbrowGitStaged"}`, `{key="unstaged", symbol="M", hl="TbrowGitUnstaged"}`, `{key="unmerged", symbol="U", hl="TbrowGitUnmerged"}`. Implement `draw_git_status(view_state, model_state, bufnr)` that: (1) clears `tbrow_git_status_ns` on the buffer, (2) iterates `view_state.line_num_to_absolute_filepath`, (3) for each file path, checks `model_state.git_status_store[status.key][file_path]` for each entry in `status_config`, (4) for each match, calls `vim.api.nvim_buf_set_extmark` with `virt_text = {{symbol, hl}}` and `priority = 3` (higher than diagnostic priority of 2, ensuring git status appears after diagnostics). Return `view_state`. Export `M.draw_git_status = draw_git_status`.

- [ ] T004 [P] [US1] Update lua/controller/initialize.lua — Import `GitStatusStore` from `model.gitstatus`. In the `new_tbrow_instance()` function, add `git_status_store` to the `ModelState:new()` constructor call, set to `GitStatusStore:refreshed()`. This ensures new browser instances have git status data populated on open. Place the field alongside the existing `diagnostic_store` initialization.

- [ ] T005 [US1] Update lua/view/drawfilesystem.lua — Import the git status view module: `local git_status = require("view.gitstatus")`. After the existing `diagnostics.draw_diagnostics()` call (which returns `view_state`), chain a call to `git_status.draw_git_status(view_state, model_state, bufnr)`. The draw pipeline becomes: write lines → icon highlights → draw_diagnostics → draw_git_status. Return the final view_state from draw_git_status.

- [ ] T006 [US1] Update lua/tbrow.lua — In the `refresh_filesystem()` function inside `setup_buffer()`, add `:withGitStatusRefreshed()` to the model_state update chain. The current line is `model_state = populatechildren.with_root_refreshed(model_state)`. After this, add `model_state = model_state:withGitStatusRefreshed()` before the `draw_filesystem` call. This ensures the manual refresh keymap (`<C-l>`) refreshes git status along with the filesystem tree.

**Checkpoint**: At this point, git status indicators (M/S/U) appear in the file browser for files with git changes. Manual refresh (`<C-l>`) updates them. Non-git projects show no indicators and no errors. User Story 1 is fully functional.

---

## Phase 3: User Story 2 — Distinguish Between Git Statuses Visually (Priority: P2)

**Goal**: Each git status type is visually distinct (different symbol and color), and files with multiple statuses (e.g., both staged and unstaged) display all applicable indicators.

**Independent Test**: Create files in each of the three git states. Verify each renders with a distinct symbol (M, S, U) and a distinct color. Partially stage a file and verify both S and M indicators appear.

### Implementation for User Story 2

- [ ] T007 [US2] Verify and refine dual-status rendering in lua/view/gitstatus.lua — Confirm that the `draw_git_status` function iterates all three status types independently per file, so a file present in both `staged` and `unstaged` sets gets two separate `nvim_buf_set_extmark` calls, each with its own `virt_text`. The rendered order should be staged (`S`) first, then unstaged (`M`), then unmerged (`U`) — matching the `status_config` iteration order from T003. Add a space separator between symbols by prefixing each symbol with a space in the `virt_text` entry (e.g., `" S"`, `" M"`, `" U"`). Verify that three distinct highlight groups are used and that no two statuses share the same symbol or highlight.

**Checkpoint**: All three git statuses are visually distinguishable. Files with multiple statuses show all applicable indicators (e.g., `S M`). User Story 2 is complete.

---

## Phase 4: User Story 3 — Git Status Updates Automatically (Priority: P3)

**Goal**: Git status indicators refresh automatically when relevant changes occur (e.g., saving a file), without requiring manual refresh.

**Independent Test**: Open the file browser. In another split, modify a tracked file and save it. Verify the git status indicator updates within 2 seconds without pressing `<C-l>`.

### Implementation for User Story 3

- [ ] T008 [US3] Add dedicated `refresh_git_status` function and `BufWritePost` autocommand in lua/tbrow.lua — Inside the `setup_buffer()` function, create a new local function `refresh_git_status()` that: (1) calls `model_state = model_state:withGitStatusRefreshed()`, (2) requires `view.gitstatus` and calls `draw_git_status(view_state, model_state, bufnr)` to re-render only git status extmarks (not a full tree re-render), (3) calls `update_global_instance()`. Then register a `BufWritePost` autocommand (pattern `*`, not buffer-local) with the callback wrapped in `debounce.with_debounce(refresh_git_status, 200)`. This 200ms debounce prevents excessive git shell-outs on rapid saves. The autocommand should be created with `vim.api.nvim_create_autocmd("BufWritePost", { callback = debounce.with_debounce(refresh_git_status, 200) })`.

**Checkpoint**: Git status indicators update automatically when any buffer is saved. The update is debounced at 200ms. User Story 3 is complete.

---

## Phase 5: User Story 4 — Directory-Level Git Status Propagation (Priority: P3)

**Goal**: Parent directories display a git status indicator when any descendant file has git changes, even when the directory is collapsed.

**Independent Test**: Modify a file inside a nested directory, collapse that directory in the file browser, and verify the parent directory shows a git status indicator. Verify clean directories show no indicator.

### Implementation for User Story 4

- [ ] T009 [US4] Verify directory propagation in lua/view/gitstatus.lua and lua/model/gitstatus.lua — The existing `get_all_roots()` function in `model/gitstatus.lua` already propagates each changed file path to all ancestor directories (e.g., `/home/user/project/src/file.lua` propagates to `/home/user/project/src/`, `/home/user/project/`, etc.). Verify that directory paths in `GitStatusStore` sets include the trailing `/` to match the `FileGraph.absolute_filepath` convention for directories. The renderer in `view/gitstatus.lua` already iterates `line_num_to_absolute_filepath` which includes both file and directory entries. Confirm that directory entries with matching paths in the git status sets correctly receive extmarks. If `get_all_roots()` does not produce paths with trailing `/` for intermediate directories, update it to ensure directory paths end with `/` — check the output format and adjust the function to append `/` to intermediate path segments. This is the only potential code change in this task.

**Checkpoint**: Collapsed directories with changed descendants show git status indicators. Clean directories show none. User Story 4 is complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, robustness, and validation across all user stories.

- [ ] T010 [P] Ensure graceful non-git behavior in lua/model/gitstatus.lua — Verify that `GitStatusStore:refreshed()` returns a store with all three sets empty (`{}`) when `is_git_repo()` returns false. Verify that `vim.fn.system()` calls for git commands do not produce error messages or shell errors in non-git directories. Ensure no `vim.notify` or error output when git is not installed (the existing `is_git_repo()` guard should handle this, but confirm the `2>/dev/null` redirect in the shell command suppresses stderr).

- [ ] T011 [P] Run quickstart.md validation — Walk through all scenarios in specs/002-git-status-extmark/quickstart.md: open browser in a git repo (indicators appear), open in a non-git directory (no indicators, no errors), verify highlight group customization works, verify `<C-l>` refresh updates indicators, verify BufWritePost triggers auto-update. Document any discrepancies.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — can start immediately. BLOCKS all user stories.
- **User Story 1 (Phase 2)**: Depends on Foundational (Phase 1) completion.
- **User Story 2 (Phase 3)**: Depends on User Story 1 (refines the renderer created in US1).
- **User Story 3 (Phase 4)**: Depends on Foundational (Phase 1). Can run in parallel with US1/US2 in theory, but logically builds on the draw pipeline from US1.
- **User Story 4 (Phase 5)**: Depends on User Story 1 (verifies model+renderer integration).
- **Polish (Phase 6)**: Depends on all user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — No dependencies on other stories. This is the MVP.
- **User Story 2 (P2)**: Refines the renderer from US1 — depends on US1 completion.
- **User Story 3 (P3)**: Adds autocommand — can technically start after Foundational, but needs the renderer from US1 to be meaningful.
- **User Story 4 (P3)**: Verification task — depends on US1 renderer + model integration.

### Within Each User Story

- T003 and T004 can run in parallel (different files, no dependencies)
- T005 depends on T003 (needs the git status module to import)
- T006 depends on T002 (needs withGitStatusRefreshed on ModelState)
- T007 depends on T003 (refines the renderer)
- T008 depends on T003 and T006 (needs renderer and model wiring)
- T009 depends on T003 and T001 (needs renderer and model)

### Parallel Opportunities

- T001 can start immediately (no dependencies)
- T003 and T004 can run in parallel (different files) once Phase 1 completes
- T010 and T011 can run in parallel (independent validation tasks)

---

## Parallel Example: User Story 1

```text
# After Phase 1 (Foundational) completes, launch in parallel:
Task T003: "Create lua/view/gitstatus.lua"       (new file, no dependencies)
Task T004: "Update lua/controller/initialize.lua" (different file, no dependencies on T003)

# Then sequentially:
Task T005: "Update lua/view/drawfilesystem.lua"   (depends on T003)
Task T006: "Update lua/tbrow.lua"                 (depends on T002)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (T001, T002)
2. Complete Phase 2: User Story 1 (T003–T006)
3. **STOP and VALIDATE**: Open browser in a git repo, verify M/S/U indicators appear. Open in non-git directory, verify no errors.
4. This delivers the core feature — git status visible in the file browser.

### Incremental Delivery

1. Foundational (T001–T002) → Model layer ready
2. User Story 1 (T003–T006) → Git status visible → **MVP!**
3. User Story 2 (T007) → Dual-status display refined
4. User Story 3 (T008) → Auto-update on save
5. User Story 4 (T009) → Directory propagation verified
6. Polish (T010–T011) → Edge cases handled, quickstart validated

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after its phase completes
- Commit after each task or logical group
- The model layer already handles ancestor directory propagation (US4) — implementation is mostly verification
- No new keymaps are introduced; existing `<C-l>` refresh is extended
- No new public API functions; existing API picks up git status through the re-render pipeline
