# Tasks: Configurable Git Marks

**Input**: Design documents from `/specs/003-configurable-git-marks/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/lua-api.md

**Tests**: No automated test framework in use. Validation is manual via file browser per quickstart.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: User Story 1 — See Untracked Files in the File Browser (Priority: P1) 🎯 MVP

**Goal**: Display a distinct git status indicator (`?`) next to untracked files and their parent directories in the file browser.

**Independent Test**: Create a new file not tracked by git (and not in `.gitignore`), open the file browser, and verify that an untracked mark (`?`) appears next to the file and its parent directories.

### Implementation for User Story 1

- [X] T001 [US1] Add `git_untracked_files()` function that shells out to `git ls-files --others --exclude-standard` and returns absolute paths, update the `@class GitStatusStore` annotation to include `untracked` field, add `untracked = {}` to the prototype table, and populate the `untracked` set in `refreshed()` using the existing pipeline (`to_absolute_paths` → `map(get_all_roots, ...)` → `flatten` → `list_to_set`) in `lua/model/gitstatus.lua`
- [X] T002 [US1] Add `vim.api.nvim_set_hl(0, "TbrowGitUntracked", { fg = "#d7875f", default = true })` highlight group definition and add `{ key = "untracked", symbol = " ?", hl = "TbrowGitUntracked" }` entry to the `status_config` table in `lua/view/gitstatus.lua`

**Checkpoint**: Untracked files should now display a `?` mark in dark orange. Verify by creating a new untracked file and opening the file browser. Files in `.gitignore` should NOT show the mark.

---

## Phase 2: User Story 2 — Updated Default Colors for Git Marks (Priority: P1)

**Goal**: Render all git marks in conventional git colors: green for staged, dark orange for modified and untracked, red for unmerged.

**Independent Test**: Open the file browser in a project with staged, modified, untracked, and unmerged files, and verify each mark renders in its expected default color.

### Implementation for User Story 2

- [X] T003 [US2] Replace the three existing `nvim_set_hl` calls: change `TbrowGitStaged` from `{ link = "DiagnosticInfo", default = true }` to `{ fg = "#608b4e", default = true }`, change `TbrowGitUnstaged` from `{ link = "DiagnosticWarn", default = true }` to `{ fg = "#d7875f", default = true }`, and change `TbrowGitUnmerged` from `{ link = "DiagnosticError", default = true }` to `{ fg = "#f44747", default = true }` in `lua/view/gitstatus.lua`

**Checkpoint**: Staged marks should be green, modified marks dark orange, untracked marks dark orange, unmerged marks red. All with `default = true` so colorschemes can still override.

---

## Phase 3: User Story 3 — Customize Git Mark Colors (Priority: P2)

**Goal**: Allow users to override the highlight attributes of any git mark type through the `setup()` configuration.

**Independent Test**: Call `setup({ git_marks = { staged = { hl = { fg = "#00ff00" } } } })`, open the file browser, and verify the staged mark uses the custom green color while other marks retain defaults.

### Implementation for User Story 3

- [X] T004 [P] [US3] Add `git_marks` option handling in the `setup()` function: store `opts.git_marks` in `vim.g.tbrow_git_marks`, then iterate the table and for each key with an `hl` field call `vim.api.nvim_set_hl(0, group_name, hl)` using the mapping `{ staged = "TbrowGitStaged", unstaged = "TbrowGitUnstaged", untracked = "TbrowGitUntracked", unmerged = "TbrowGitUnmerged" }` in `lua/tbrow.lua`

**Checkpoint**: Custom highlight colors should take effect for overridden marks. Non-overridden marks should retain default colors. Passing no `git_marks` or nil should keep all defaults.

---

## Phase 4: User Story 4 — Customize Git Mark Text (Priority: P2)

**Goal**: Allow users to override the text/symbol of any git mark type through the `setup()` configuration, including hiding marks with an empty string.

**Independent Test**: Call `setup({ git_marks = { unstaged = { text = " ●" } } })`, open the file browser, and verify the modified mark shows `●` while other marks show default text.

### Implementation for User Story 4

- [X] T005 [US4] Update the render loop in `draw_git_status()` to resolve mark text from `vim.g.tbrow_git_marks`: for each status, check if `vim.g.tbrow_git_marks` has a `text` field for that key (treating `nil` as "use default" and `""` as "hide mark"), falling back to `status.symbol` from the `status_config` defaults, and skip appending to `virt_text` when text is empty in `lua/view/gitstatus.lua`

**Checkpoint**: Custom text should appear for overridden marks. Empty string should hide the mark entirely. Non-overridden marks should show default text (S/M/?/U).

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final validation of all user stories working together

- [X] T006 Validate all quickstart.md scenarios: verify default marks render correctly (S green, M dark orange, ? dark orange, U red), verify partial overrides work (custom text only, custom color only, mixed), verify empty string hides a mark, and verify highlight group links work via `setup()` configuration

---

## Dependencies & Execution Order

### Phase Dependencies

- **US1 (Phase 1)**: No dependencies — can start immediately
- **US2 (Phase 2)**: Shares `lua/view/gitstatus.lua` with US1 — execute after Phase 1
- **US3 (Phase 3)**: Independent file (`lua/tbrow.lua`) — can start in parallel with Phase 1
- **US4 (Phase 4)**: Shares `lua/view/gitstatus.lua` with US1/US2 and needs US3 config mechanism — execute after Phases 2 and 3
- **Polish (Phase 5)**: Depends on all previous phases

### User Story Dependencies

- **US1 (P1)**: No dependencies on other stories
- **US2 (P1)**: No logical dependency on US1, but shares file — execute sequentially
- **US3 (P2)**: Fully independent — different file, no shared state
- **US4 (P2)**: Needs US3's `vim.g.tbrow_git_marks` storage mechanism; shares file with US1/US2

### Parallel Opportunities

- **T004 [US3]** in `lua/tbrow.lua` can run in parallel with **T001 [US1]** and **T002 [US1]** in `lua/model/gitstatus.lua` and `lua/view/gitstatus.lua`
- After Phase 1, **T003 [US2]** and **T004 [US3]** can run in parallel (different files)

---

## Parallel Example: US3 + US1/US2

```bash
# These can run in parallel (different files, no dependencies):
Task: T001 [US1] — Add untracked to GitStatusStore in lua/model/gitstatus.lua
Task: T004 [US3] — Add git_marks config to setup() in lua/tbrow.lua

# Then after T001 completes:
Task: T002 [US1] — Add untracked to view layer in lua/view/gitstatus.lua
# (T004 can still be running in parallel)

# Then sequentially on lua/view/gitstatus.lua:
Task: T003 [US2] — Update default colors
Task: T005 [US4] — Add text resolution from config
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: User Story 1 (model + view)
2. **STOP and VALIDATE**: Create an untracked file and verify the `?` mark appears
3. This delivers the primary new capability: untracked file visibility

### Incremental Delivery

1. Phase 1: US1 → Untracked files visible in file browser (MVP!)
2. Phase 2: US2 → All marks use correct git-conventional colors
3. Phase 3: US3 → Users can customize mark colors via `setup()`
4. Phase 4: US4 → Users can customize mark text via `setup()`
5. Phase 5: Polish → Full validation against quickstart.md
6. Each phase adds value without breaking previous functionality

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- This feature modifies 3 existing files — no new files created in source code
- All highlight groups use `default = true` so colorschemes can override
- `vim.g.tbrow_git_marks` follows the established pattern of `vim.g.tbrow_icons`
- Commit after each phase for clean incremental delivery
