# Feature Specification: File Browser

**Feature Branch**: `001-file-browser`
**Created**: 2026-03-25
**Status**: Draft
**Input**: User description: "Build a Neovim plugin to serve as a directory/file browser. It feels Vim-native and lightweight. It uses standard Vim motions to navigate inside the buffer. It is highly extensible, being configurable and controllable entirely through a Lua API and able to render in the context of any Neovim window."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse Project File Tree (Priority: P1)

A developer opens Neovim in a project directory and invokes the file browser to see the project's directory structure. They use familiar Vim motions (`j`, `k`, `gg`, `G`, `/` search) to move through the listing, and all other non-editing Vim features — registers, macros, visual mode, yanking, marks — work exactly as they would in any normal buffer. They expand and collapse directories inline to explore nested folders, then select a file to open it in their editor.

**Why this priority**: This is the core value proposition — a user must be able to see their project structure and navigate it using standard Vim motions. Without this, nothing else matters.

**Independent Test**: Can be fully tested by opening the browser in a project directory, navigating with `j`/`k`, expanding a directory, and opening a file. Delivers the fundamental file browsing experience.

**Acceptance Scenarios**:

1. **Given** a user is editing a file in Neovim, **When** they invoke the file browser, **Then** the current window displays a tree-style listing of the working directory with files and directories clearly distinguished.
2. **Given** the file browser is open, **When** the user presses `j` and `k`, **Then** the cursor moves down and up through the file listing exactly as it would in any normal buffer.
3. **Given** the file browser is open and the cursor is on a collapsed directory, **When** the user activates the expand action, **Then** the directory's children appear indented beneath it in the listing.
4. **Given** the file browser is open and the cursor is on an expanded directory, **When** the user activates the collapse action, **Then** the directory's children are hidden and the directory shows as collapsed.
5. **Given** the file browser is open and the cursor is on a file, **When** the user activates the primary open action, **Then** the file opens in the current browser window, replacing the browser.
6. **Given** the file browser is open and the cursor is on a file, **When** the user activates the secondary open action, **Then** the file opens in the previous window (the most recently focused non-browser window), and the browser remains visible.

---

### User Story 2 - Contextual File Awareness (Priority: P2)

A developer is editing a deeply nested file and wants to see where it sits in the project. They open the file browser and it automatically reveals the current file's location in the tree, scrolling to and highlighting it so the developer immediately has context.

**Why this priority**: Knowing "where you are" in a project is the second most important capability after basic navigation. It transforms the browser from a static listing into a contextual tool.

**Independent Test**: Can be tested by opening a deeply nested file, invoking the browser, and verifying the tree is expanded to show and highlight that file's location.

**Acceptance Scenarios**:

1. **Given** the user is editing a file at a nested path, **When** they open the file browser, **Then** all ancestor directories of the current file are expanded and the current file's entry is visible.
2. **Given** the file browser is open and showing the current file, **When** the user navigates to and opens a different file, then re-invokes the browser, **Then** the browser updates to reveal the newly opened file's location.

---

### User Story 3 - Visual Feedback via Icons and Diagnostics (Priority: P3)

A developer is scanning the file tree to locate files with errors or recent changes. The browser displays file-type icons next to each entry for quick visual identification, diagnostic indicators (errors, warnings) next to affected files, and git status markers showing which files have been modified.

**Why this priority**: Visual cues accelerate navigation and decision-making. Icons help users distinguish file types at a glance; diagnostics and git status surface actionable information without leaving the browser.

**Independent Test**: Can be tested by introducing a syntax error in a file and an unstaged change, opening the browser, and verifying the appropriate diagnostic and git indicators appear next to those files.

**Acceptance Scenarios**:

1. **Given** the file browser is open, **When** files of different types are listed, **Then** each file displays an icon corresponding to its file type (e.g., distinct icons for Lua files, Markdown files, configuration files).
2. **Given** a file has active diagnostic errors, **When** the file browser renders, **Then** a visual indicator of the highest-severity diagnostic appears next to that file's entry.
3. **Given** a file has unstaged or staged git changes, **When** the file browser renders, **Then** a visual indicator of the git status appears next to that file's entry.
4. **Given** a directory contains files with diagnostics, **When** the file browser renders, **Then** the directory's indicator reflects the most severe diagnostic among its descendants.

---

### User Story 4 - Quick File Actions (Priority: P4)

A developer needs to quickly copy a file path or filename to the clipboard while browsing. They position the cursor on a file and invoke a yank action to copy the full path or just the filename, then paste it elsewhere in their workflow.

**Why this priority**: Copy-to-clipboard is a common utility action that enhances the browser's usefulness beyond pure navigation.

**Independent Test**: Can be tested by positioning the cursor on a file, invoking the yank-path action, and pasting the result to verify the correct path was copied.

**Acceptance Scenarios**:

1. **Given** the file browser is open and the cursor is on a file, **When** the user invokes the "yank directory" action, **Then** the file's directory path is copied to the system clipboard.
2. **Given** the file browser is open and the cursor is on a file, **When** the user invokes the "yank filename" action, **Then** the file's name is copied to the system clipboard.

---

### User Story 5 - Render in Any Window (Priority: P5)

A developer wants to display the file browser in a specific window layout — for example, in a vertical split on the left, in a floating window, or replacing the content of the current window. The plugin's programmatic API allows opening the browser targeted at any existing or new window, so the user or other plugins can control exactly where the browser appears.

**Why this priority**: Rendering flexibility is what makes the plugin composable and embeddable. It enables integration with custom layouts, tab workflows, and other plugins.

**Independent Test**: Can be tested by programmatically opening the browser in the current window, then in a split window, and verifying it renders correctly in each context.

**Acceptance Scenarios**:

1. **Given** the user calls the browser's open function targeting the current window, **When** the function executes, **Then** the file browser replaces the current window's content.
2. **Given** an external plugin creates a new split window and calls the browser's open function targeting that window, **When** the function executes, **Then** the file browser renders inside the specified split window.
3. **Given** the browser is open in one window and the user activates the secondary open action on a file, **When** the file opens, **Then** it opens in the previous window (not the browser window), preserving the browser's presence.

---

### User Story 6 - Lua API for Extensibility (Priority: P6)

A plugin author or advanced user wants to extend or integrate the file browser. They use the Lua API to programmatically query the file under the cursor, respond to browser events, customize icon mappings, or control the browser's behavior. All configuration is done through Lua — no Vimscript or ex-commands are required for setup.

**Why this priority**: A clean Lua API is the foundation for extensibility. Without it, the plugin is a closed box. With it, the plugin becomes a building block for custom workflows.

**Independent Test**: Can be tested by writing a Lua script that calls the API to open the browser, query the file under the cursor, and verify the returned data is correct.

**Acceptance Scenarios**:

1. **Given** the browser is open, **When** a Lua script calls the "file under cursor" API function, **Then** the function returns the full path of the file at the cursor's current position.
2. **Given** the browser is open, **When** a Lua script calls the "directory under cursor" API function, **Then** the function returns the directory path of the entry at the cursor's current position.
3. **Given** a user defines custom icon mappings in their Lua configuration, **When** the browser renders, **Then** the custom icons are used instead of the defaults.
4. **Given** the browser exposes a setup function, **When** the user calls it with no arguments, **Then** the browser initializes with sensible defaults and is ready to use.

---

### Edge Cases

- What happens when the browser is opened in an empty directory with no files or subdirectories? The browser should display an empty listing without errors.
- What happens when a directory contains thousands of files? The browser should render without noticeable lag and remain responsive to Vim motions.
- What happens when a file or directory is deleted, renamed, or created on disk while the browser is open? The browser should update its listing when the user explicitly refreshes.
- What happens when the user expands a directory they do not have read permission for? The browser should display a clear indication that the directory cannot be read, without crashing.
- What happens when the browser is opened but no git repository is present? Git status indicators should simply not appear; the browser should function normally otherwise.
- What happens when diagnostic information changes while the browser is open? The browser should update diagnostic indicators automatically (debounced to avoid excessive re-renders).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The plugin MUST display the file system as an indented tree structure within a Neovim buffer, showing directories and files with clear visual hierarchy.
- **FR-002**: All core Vim functionality that does not involve editing buffer content MUST work as-is inside the browser buffer. This includes standard motions (`j`, `k`, `gg`, `G`, `Ctrl-d`, `Ctrl-u`, `/` search), registers, macros, visual mode, yanking, marks, and any other non-editing Vim features — none of these may be overridden or remapped by the plugin.
- **FR-003**: The plugin MUST allow users to expand a collapsed directory to reveal its children inline in the tree.
- **FR-004**: The plugin MUST allow users to collapse an expanded directory to hide its children inline in the tree.
- **FR-005**: The plugin MUST provide a primary open action that opens the selected file in the current browser window, replacing the browser.
- **FR-005a**: The plugin MUST provide a secondary open action that opens the selected file in the previous window (the most recently focused non-browser window), preserving the browser's presence.
- **FR-005b**: Any additional custom window-targeting behavior for file opening is the responsibility of the user or configurer via the Lua API; the plugin MUST NOT impose other built-in open behaviors beyond the two above.
- **FR-006**: The plugin MUST display file-type icons next to each entry, with icons visually distinguishable by file extension or type.
- **FR-007**: The plugin MUST display diagnostic indicators (error, warning, info, hint) next to files that have active diagnostics, reflecting the highest severity level.
- **FR-008**: The plugin MUST display git status indicators next to files that have unstaged, staged, or unmerged changes.
- **FR-009**: The plugin MUST automatically reveal and scroll to the currently edited file's location in the tree when opened.
- **FR-010**: The plugin MUST provide a yank-to-clipboard action for copying a file's directory path.
- **FR-011**: The plugin MUST provide a yank-to-clipboard action for copying a file's name.
- **FR-012**: The plugin MUST expose a Lua function to open the browser targeting any specified Neovim window, rendering the tree inside that window. Multiple browser instances MAY coexist in different windows simultaneously, each maintaining independent tree state.
- **FR-013**: The plugin MUST expose a Lua function to open the browser in the current window, replacing its content with the file tree.
- **FR-014**: The plugin MUST expose a Lua API function that returns the file path under the cursor's current position.
- **FR-015**: The plugin MUST expose a Lua API function that returns the directory path under the cursor's current position.
- **FR-016**: The plugin MUST allow customization of file-type icon mappings through user configuration.
- **FR-017**: The plugin MUST provide a setup function that initializes the browser with sensible defaults when called with no arguments.
- **FR-018**: The plugin MUST provide a manual refresh action that re-reads the file system and updates the displayed tree.
- **FR-019**: The plugin MUST automatically update diagnostic indicators when diagnostic information changes, using debounced rendering to prevent excessive updates.
- **FR-020**: The browser buffer MUST be non-editable (read-only) to prevent accidental modification of the file listing.
- **FR-021**: Files and directories within each level of the tree MUST be sorted with directories grouped before files; within each group, entries are sorted alphabetically in ascending order.
- **FR-022**: Hidden files and directories (names beginning with `.`) MUST be visible by default.
- **FR-023**: The plugin MUST provide a toggle action that hides or reveals hidden files and directories, updating the tree display immediately.

### Key Entities

- **File Tree Node**: Represents a single file or directory in the tree. Attributes: path, name, type (file or directory), expansion state (expanded/collapsed for directories), depth level, children (for directories).
- **File Metadata**: Diagnostic and version control information associated with a file. Attributes: diagnostic severity level, git status (unstaged, staged, unmerged).
- **Browser Instance**: A single rendering of the file browser in a window. Each instance maintains its own independent tree state (expansion, collapse, hidden-file visibility). Multiple instances may coexist in different windows simultaneously without sharing state. Attributes: root directory path, associated window, associated buffer, current tree state.
- **Icon Mapping**: Association between a file type/extension and its visual icon representation. Attributes: file extension or type identifier, icon character, highlight group.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can open the file browser, navigate to a file, and open it within 5 seconds for a typical project (under 1,000 files).
- **SC-002**: All non-editing Vim functionality (motions, registers, macros, visual mode, yanking, marks) works identically in the browser buffer as in any normal buffer, with zero custom overrides of these features.
- **SC-003**: The browser renders a directory tree of 500 entries in under 1 second on typical hardware, with no visible flicker or lag during expand/collapse operations.
- **SC-004**: 100% of browser functionality is accessible through the Lua API — no feature requires Vimscript or ex-commands for programmatic access.
- **SC-005**: The browser can be rendered in any Neovim window context (current window, split, or externally created window) without layout errors or rendering artifacts.
- **SC-006**: Diagnostic indicator updates appear within 2 seconds of a diagnostic change, without causing re-render storms or user-visible stutter.
- **SC-007**: The browser operates correctly in projects with no git repository, displaying all features except git status indicators.
- **SC-008**: A new user can install the plugin, call the setup function with no arguments, and have a fully functional file browser on first use.

## Clarifications

### Session 2026-03-25

- Q: Scope of non-editing Vim features in browser buffer? → A: All non-editing core Vim functionality (registers, macros, visual mode, yanking, marks) works as-is — no overrides.
- Q: Which window receives files opened from the browser? → A: Primary action opens in current (browser) window, replacing the browser; secondary action opens in the previous window, preserving the browser. Any other custom window behavior is the configurer's responsibility via the Lua API.
- Q: How are hidden/dot files handled? → A: Visible by default, with a toggle action to hide/show them.
- Q: Do multiple browser windows share tree state? → A: No — each instance is independent with its own expansion/collapse and visibility state.
- Q: Directory sort grouping — intermixed or directories first? → A: Directories first, then files, each group sorted A-Z.

## Assumptions

- Users are running Neovim 0.8 or later, which provides the required Lua API surface and diagnostic infrastructure.
- Users are familiar with standard Vim motions and expect the browser buffer to behave like a normal read-only buffer.
- The plugin does not need to support remote file systems or network-mounted directories in this version; it operates on the local file system only.
- File-type icon rendering requires a Nerd Font or similar patched font installed on the user's terminal; the plugin assumes such a font is available but degrades gracefully without one.
- Git status detection relies on the `git` command-line tool being available in the user's PATH.
- The plugin does not perform file system mutation (create, delete, rename, move) in this version — it is a read-only browser.
- The browser's root directory defaults to the current working directory unless otherwise specified through the API.
- Diagnostic integration uses Neovim's built-in diagnostic framework and does not depend on any specific language server or linter.
