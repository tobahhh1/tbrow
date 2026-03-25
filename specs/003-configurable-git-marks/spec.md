# Feature Specification: Configurable Git Marks

**Feature Branch**: `003-configurable-git-marks`  
**Created**: 2026-03-25  
**Status**: Draft  
**Input**: User description: "Git mark colors and text should be configurable. There should be a git mark for untracked files. They should default to: Green: staged, Dark Orange: modified / untracked (keep letters separate), Red: Unmerged"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Untracked Files in the File Browser (Priority: P1)

A developer creates new files in their project that have not yet been added to git. When they open the file browser, each untracked file displays a distinct git status indicator so the developer can immediately see which files are new and not yet tracked by version control.

**Why this priority**: Untracked files are currently invisible in the git status display. This is the primary new capability requested — developers need to see untracked files alongside modified, staged, and unmerged files for a complete picture of their working tree.

**Independent Test**: Can be fully tested by creating a new file that is not tracked by git, opening the file browser, and verifying that an untracked status indicator appears next to the file entry.

**Acceptance Scenarios**:

1. **Given** a file exists in the working tree but is not tracked by git, **When** the file browser renders, **Then** an untracked git status indicator appears at the end of that file's line.
2. **Given** an untracked file exists inside a directory, **When** the parent directory is visible in the file browser, **Then** the parent directory also displays an untracked status indicator (propagation).
3. **Given** a file is tracked by git and has no changes, **When** the file browser renders, **Then** no untracked indicator appears for that file.
4. **Given** a file listed in `.gitignore` exists, **When** the file browser renders, **Then** no untracked indicator appears for that ignored file.

---

### User Story 2 - Updated Default Colors for Git Marks (Priority: P1)

A developer opens the file browser with default settings and sees git status marks rendered in colors that match conventional git semantics: green for staged changes, dark orange for modifications and untracked files, and red for unmerged conflicts. The colors are distinct enough to scan at a glance without reading the mark letters.

**Why this priority**: The current default colors link to diagnostic highlight groups that don't align with conventional git color semantics. Updated defaults deliver immediate visual improvement for all users without any configuration.

**Independent Test**: Can be tested by opening the file browser in a project with staged, modified, untracked, and unmerged files, and verifying each mark renders in its expected default color.

**Acceptance Scenarios**:

1. **Given** a file has staged changes and default settings are used, **When** the file browser renders, **Then** the staged mark appears in green.
2. **Given** a file has unstaged modifications and default settings are used, **When** the file browser renders, **Then** the modified mark appears in dark orange.
3. **Given** a file is untracked and default settings are used, **When** the file browser renders, **Then** the untracked mark appears in dark orange.
4. **Given** a file is in an unmerged state and default settings are used, **When** the file browser renders, **Then** the unmerged mark appears in red.
5. **Given** a file has both staged and unstaged changes, **When** the file browser renders, **Then** the staged mark appears in green and the modified mark appears in dark orange, as separate indicators.

---

### User Story 3 - Customize Git Mark Colors (Priority: P2)

A developer wants git marks to match their personal color scheme or accessibility needs. They provide color overrides through the plugin's setup configuration, and the file browser renders git marks using those custom colors instead of the defaults.

**Why this priority**: Configurability is essential for a Neovim plugin — users expect to be able to adapt visual elements to their personal workflow and colorscheme. However, the defaults must work well first (P1), so customization is a follow-on concern.

**Independent Test**: Can be tested by passing custom color values in the plugin's setup configuration, opening the file browser, and verifying that git marks render in the specified custom colors instead of the defaults.

**Acceptance Scenarios**:

1. **Given** a user provides custom color settings for staged marks in their setup configuration, **When** the file browser renders staged files, **Then** the staged mark uses the user-specified color.
2. **Given** a user provides custom color settings for only some mark types, **When** the file browser renders, **Then** the customized marks use user-specified colors and uncustomized marks use defaults.
3. **Given** a user provides no custom color settings, **When** the file browser renders, **Then** all marks use the default colors.

---

### User Story 4 - Customize Git Mark Text (Priority: P2)

A developer prefers different symbols for git status marks — for example, using icons from a Nerd Font instead of letters, or using different letters that better fit their mental model. They provide custom text values through the plugin's setup configuration, and the file browser renders those custom symbols.

**Why this priority**: Text customization complements color customization and gives users full control over the visual appearance of git marks. Like color customization, the defaults must work first.

**Independent Test**: Can be tested by passing custom text values for git marks in the setup configuration, opening the file browser, and verifying the custom symbols appear in place of the defaults.

**Acceptance Scenarios**:

1. **Given** a user provides a custom text string for the modified mark, **When** the file browser renders modified files, **Then** the custom text appears instead of the default letter.
2. **Given** a user provides custom text for only some mark types, **When** the file browser renders, **Then** the customized marks show user-specified text and uncustomized marks show default text.
3. **Given** a user provides an empty string as custom text for a mark type, **When** the file browser renders files with that status, **Then** no text is rendered for that mark type (effectively disabling it).

---

### Edge Cases

- What happens when a file is both modified and untracked? This cannot occur — a file is either tracked (and possibly modified) or untracked. These are mutually exclusive git states.
- What happens when a user provides an invalid color value? The plugin should fall back to the default color for that mark type and not produce errors.
- What happens when a user provides very long custom text for a mark? The text is rendered as-is; the user is responsible for choosing text that fits their layout.
- What happens when the terminal does not support the configured colors? The terminal's nearest color approximation is used, which is standard terminal behavior.
- What happens when a directory contains both modified and untracked descendant files? The directory should show both the modified and untracked indicators (propagation applies to each status independently).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The file browser MUST display a git status indicator for untracked files (files not tracked by git and not ignored).
- **FR-002**: Untracked files MUST use a mark letter that is distinct from the existing modified, staged, and unmerged marks.
- **FR-003**: The default color for staged marks MUST be green.
- **FR-004**: The default color for modified (unstaged) marks MUST be dark orange.
- **FR-005**: The default color for untracked marks MUST be dark orange.
- **FR-006**: The default color for unmerged marks MUST be red.
- **FR-007**: Modified and untracked marks MUST display as separate indicators with their own letters, even when they share the same color.
- **FR-008**: Users MUST be able to override the color of each git mark type (staged, modified, untracked, unmerged) through the plugin's setup configuration.
- **FR-009**: Users MUST be able to override the text/symbol of each git mark type through the plugin's setup configuration.
- **FR-010**: When a user provides partial overrides (only some mark types), unconfigured marks MUST retain their default color and text.
- **FR-011**: The untracked status MUST propagate to parent directories, consistent with how other git statuses propagate.
- **FR-012**: Files listed in `.gitignore` MUST NOT be marked as untracked.

### Key Entities

- **Git Mark Configuration**: A per-mark-type setting comprising a text/symbol string and a color/highlight value. Each of the four mark types (staged, modified, untracked, unmerged) has its own configuration entry.
- **Untracked Status**: A new git status category representing files present in the working tree that are not tracked by git and not ignored. Behaves identically to other statuses in terms of display and directory propagation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All four git status types (staged, modified, untracked, unmerged) are visually distinguishable from each other by mark text without relying on color alone.
- **SC-002**: Users can identify the git status of any visible file within 2 seconds of scanning the file browser.
- **SC-003**: Users can customize the color and text of any git mark type through a single configuration point, with changes taking effect on the next file browser open.
- **SC-004**: The default color scheme matches the specified conventions (green/staged, dark orange/modified, dark orange/untracked, red/unmerged) without any user configuration.
- **SC-005**: Untracked files are displayed with the same rendering quality and positioning as other git status marks.

## Assumptions

- The existing git status model and view infrastructure (from feature 002-git-status-extmark) will be extended to support the new untracked status and configuration options.
- The plugin's `setup()` function is the standard configuration entry point, consistent with the existing options pattern (`reuse_buffers`, `indent_string`, `directories_first`, `icons`).
- "Dark orange" refers to a color value in the orange family (e.g., `#ff8800` or similar) that is visibly distinct from both red and yellow on typical terminal colorschemes.
- Modified and untracked marks share a default color but have separate mark letters (e.g., "M" for modified, "?" for untracked) so they remain distinguishable.
- Users who override highlight groups directly (e.g., via `vim.api.nvim_set_hl`) can still customize marks outside of the setup configuration; the setup-based configuration is an additional, more accessible mechanism.
