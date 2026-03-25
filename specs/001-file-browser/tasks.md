# Tasks: File Browser

**Input**: Design documents from `/specs/001-file-browser/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Note**: The tbrow codebase already implements the majority of specified features (FR-001 through FR-021). These tasks cover the remaining gaps: hidden-file toggling (FR-023), `<CR>` behavior fix (FR-005), setup options formalization (FR-017), window-targeting API (FR-012), and edge case hardening.

**Already Complete** (no tasks needed): US2 (Contextual File Awareness), US3 (Visual Feedback via Icons and Diagnostics), US4 (Quick File Actions). These are fully implemented in the existing codebase and verified against their acceptance scenarios.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Core model and controller changes that block user story work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T001 Add `show_hidden` boolean field (default `true`) to ModelState and implement `withHiddenToggled()` method that returns a new ModelState with the field inverted in lua/model/state.lua
- [X] T002 Refactor `<CR>` keymap handler in lua/tbrow.lua to use explicit file-vs-directory check (`path_is_directory()`) instead of pcall/error-driven fallback — on a directory call `toggle_directory_expanded`, on a file call `open_file("0", ...)` to open in current window
- [X] T003 Upgrade `setup()` in lua/tbrow.lua to accept an options table parameter and apply configuration from it (`reuse_buffers`, `indent_string`, `directories_first`, `icons`) per the API contract in contracts/lua-api.md, falling back to current defaults when options are not provided

**Checkpoint**: ModelState supports hidden-file state, `<CR>` behavior is spec-compliant, setup accepts config options

---

## Phase 2: User Story 1 — Browse Project File Tree (Priority: P1) 🎯 MVP

**Goal**: Complete the hidden-file toggle feature — the last missing piece of core browsing

**Independent Test**: Open the browser, press `gh` to toggle — hidden files (dotfiles) disappear and reappear. All other navigation and actions still work.

- [X] T004 [US1] Add hidden-file filtering in the `draw_filesystem` stack loop in lua/view/drawfilesystem.lua — skip nodes whose filename starts with `.` when `model_state.show_hidden` is `false`, preserving all existing rendering logic (icons, highlights, position mappings)
- [X] T005 [US1] Add `toggle_hidden` action in lua/controller/actions.lua that accepts a ModelState and returns a new ModelState with `show_hidden` inverted via `withHiddenToggled()`
- [X] T006 [US1] Wire `gh` keymap in lua/tbrow.lua to call the `toggle_hidden` action, re-render via `draw_filesystem`, and update the global instance registry — following the same pattern as the existing `<C-l>` refresh keymap

**Checkpoint**: User Story 1 is fully functional — core browsing with directory expand/collapse, file open (primary in current window, secondary in previous window), hidden-file toggle, and all Vim motions working as-is

---

## Phase 3: User Story 5 — Render in Any Window (Priority: P5)

**Goal**: Expose a Lua API function that opens the browser in any specified window, enabling plugin authors and custom layouts

**Independent Test**: From Lua, create a split window, call the open-in-window API targeting that split, verify the browser renders inside it with independent state

- [X] T007 [US5] Create `open_in_win(absolute_filepath, winnr)` function in lua/api/file.lua that initializes a new browser instance in the specified window — delegating to `controller/initialize.new_tbrow_instance()` and `controller/initialize.open_in_win()`, registering the instance in `TbrowBufnrToInstance`, and attaching keymaps to the new buffer
- [X] T008 [US5] Re-export `open_in_win` via the `M.api` table in lua/tbrow.lua so it is accessible as `require("tbrow").api.open_in_win(path, winnr)`

**Checkpoint**: User Story 5 is complete — browser can be opened in any Neovim window via the Lua API, with each instance maintaining independent state

---

## Phase 4: User Story 6 — Lua API for Extensibility (Priority: P6)

**Goal**: Formalize and complete the public API surface so all browser capabilities are programmatically accessible

**Independent Test**: From a Lua script, call setup with custom options, open the browser, call file_under_cursor, call directory_under_cursor, call toggle_hidden — all return correct values

- [X] T009 [P] [US6] Add `toggle_hidden(winnr)` function to lua/api/file.lua that looks up the browser instance by window, calls `withHiddenToggled()` on its ModelState, re-renders, updates the registry, and returns the new `show_hidden` value as a plain boolean
- [X] T010 [P] [US6] Add `refresh(winnr)` function to lua/api/file.lua that looks up the browser instance by window, calls `with_root_refreshed()`, re-renders, and updates the registry
- [X] T011 [US6] Re-export `toggle_hidden` and `refresh` via the `M.api` table in lua/tbrow.lua and verify all API functions in the `api` table match the contract defined in contracts/lua-api.md

**Checkpoint**: User Story 6 is complete — 100% of browser functionality is accessible through the Lua API

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Edge case hardening, error handling, and cleanup

- [X] T012 [P] Handle empty directory edge case in lua/view/drawfilesystem.lua — ensure an expanded directory with zero children renders without errors and does not leave the buffer in an inconsistent state
- [X] T013 [P] Handle permission-denied edge case in lua/model/populatechildren.lua `expand_children()` — catch `ls` failures gracefully and return an empty children table (or a sentinel indicating error) instead of propagating the error to the user
- [X] T014 [P] Handle no-git-repository edge case in lua/model/gitstatus.lua — check git command exit codes and return empty sets when not in a git repository, suppressing error messages
- [X] T015 Audit all buffer-local keymaps in lua/tbrow.lua to confirm no default Vim motion is overridden per FR-002 and constitution principle III — document the audit result as a comment in the keymap section

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — can start immediately
- **US1 (Phase 2)**: Depends on T001 (show_hidden on ModelState) and T002 (<CR> fix)
- **US5 (Phase 3)**: Depends on Phase 1 completion (setup options for new instances)
- **US6 (Phase 4)**: Depends on Phase 2 (toggle_hidden action exists) and Phase 3 (open_in_win exists)
- **Polish (Phase 5)**: Can start after Phase 1; no dependency on user story phases

### Already Complete User Stories (No Tasks Required)

- **User Story 2 — Contextual File Awareness (P2)**: Implemented via `new_tbrow_instance()` which auto-expands to the current file's path and `open_in_win()` which positions the cursor. ✅
- **User Story 3 — Visual Feedback via Icons and Diagnostics (P3)**: Implemented via `lua/view/icons.lua` (29+ file type icons), `lua/view/diagnostic.lua` (extmark rendering), `lua/model/diagnostic.lua` (severity propagation), and `lua/model/gitstatus.lua` (git status cache). ✅
- **User Story 4 — Quick File Actions (P4)**: Implemented via `yd` and `yc` keymaps using `vim.fn.setreg()` with register support via `vim.v.register`. ✅

### Within Each User Story

- Foundational changes before story-specific work
- Model changes before view changes
- Controller/actions before keymap wiring
- API exposure after core implementation

### Parallel Opportunities

Within Phase 1:
```
T001 (model: show_hidden)  ║  T002 (controller: <CR> fix)  ║  T003 (setup: options)
```

Within Phase 4 (US6):
```
T009 (api: toggle_hidden)  ║  T010 (api: refresh)
```

Within Phase 5 (Polish):
```
T012 (edge: empty dir)  ║  T013 (edge: permissions)  ║  T014 (edge: no git)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (T001–T003)
2. Complete Phase 2: User Story 1 (T004–T006)
3. **STOP and VALIDATE**: Open browser, expand/collapse directories, open files with `<CR>` and `p`/`P`, toggle hidden files with `gh`, verify all Vim motions work
4. This delivers a fully functional file browser — everything else is API surface and hardening

### Incremental Delivery

1. Foundational → ModelState + behavior fixes ready
2. US1 → Hidden file toggle → **MVP complete**
3. US5 → Window targeting API → Composable with other plugins
4. US6 → Full API surface → Extensibility complete
5. Polish → Production-quality edge case handling
6. Each phase adds value without breaking previous functionality

---

## Notes

- All tasks modify files under `lua/` at the repository root
- The existing MVC layer structure is preserved — no new directories needed
- Constitution compliance: all tasks follow MVC separation, immutable state, native buffer citizenship, and API-first principles
- No test tasks included (not requested in spec); test harness can be added in a future iteration
- The `<CR>` fix (T002) eliminates error-driven control flow, making the primary open action explicit and reliable
