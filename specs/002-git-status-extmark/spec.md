# Feature Specification: Git Status Extmark in File Browser

**Feature Branch**: `002-git-status-extmark`  
**Created**: 2026-03-25  
**Status**: Draft  
**Input**: User description: "The file browser should show the git status of a file next to the diagnostic extmark"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Git Status at a Glance (Priority: P1)

A developer opens the file browser to navigate their project. Files that have been modified, staged, or are in a merge conflict each display a distinct visual indicator at the end of the line, positioned next to any existing diagnostic indicator. The developer can immediately tell which files have uncommitted changes without leaving the file browser or running a separate git command.

**Why this priority**: This is the core value proposition — surfacing git status inline removes the need to switch context to a terminal or status bar. It directly answers the question "which files have I changed?" while browsing.

**Independent Test**: Can be fully tested by modifying a file, staging a file, and creating a merge conflict, then opening the file browser and verifying each status indicator appears next to the correct file entry.

**Acceptance Scenarios**:

1. **Given** a file has unstaged changes, **When** the file browser renders, **Then** a git status indicator for unstaged changes appears at the end of that file's line.
2. **Given** a file has staged changes, **When** the file browser renders, **Then** a git status indicator for staged changes appears at the end of that file's line.
3. **Given** a file is in an unmerged (conflict) state, **When** the file browser renders, **Then** a git status indicator for unmerged changes appears at the end of that file's line.
4. **Given** a file has both a diagnostic indicator and a git status, **When** the file browser renders, **Then** both indicators appear on the same line, with the git status indicator positioned adjacent to the diagnostic indicator.
5. **Given** a file has no git changes, **When** the file browser renders, **Then** no git status indicator appears for that file.

---

### User Story 2 - Distinguish Between Git Statuses Visually (Priority: P2)

A developer working on a complex branch with many changed files needs to quickly distinguish between unstaged modifications, staged files ready for commit, and unmerged conflicts. Each status type uses a visually distinct indicator (different symbol and/or color) so the developer can scan the tree and immediately prioritize their workflow — for example, resolving conflicts first, then reviewing staged files.

**Why this priority**: Without visual differentiation, showing git status has limited value. Developers need to distinguish status types to make decisions about their workflow.

**Independent Test**: Can be tested by creating files in each of the three git states (unstaged, staged, unmerged) and verifying that each state renders with a distinct visual appearance that is distinguishable from the others.

**Acceptance Scenarios**:

1. **Given** files exist in each of the three git states (unstaged, staged, unmerged), **When** the file browser renders, **Then** each state is represented by a visually distinct indicator.
2. **Given** a file has both staged and unstaged changes, **When** the file browser renders, **Then** both status indicators appear, showing the file's dual state.

---

### User Story 3 - Git Status Updates Automatically (Priority: P3)

A developer has the file browser open while working. They modify a file in another split, stage changes from a terminal, or resolve a merge conflict. The file browser's git status indicators update to reflect the new state without requiring a manual refresh.

**Why this priority**: Stale indicators are misleading. Automatic updates ensure the file browser remains a reliable source of truth as the developer works.

**Independent Test**: Can be tested by opening the file browser, then modifying a tracked file in another buffer or running a git command, and verifying the git status indicator updates within a reasonable time.

**Acceptance Scenarios**:

1. **Given** the file browser is open, **When** a file is modified in another buffer, **Then** the git status indicator for that file updates to reflect the new unstaged state.
2. **Given** the file browser is open, **When** the user manually refreshes the file browser, **Then** all git status indicators are recalculated and rendered.

---

### User Story 4 - Directory-Level Git Status Propagation (Priority: P3)

A developer browses a project with deeply nested directories. When a file inside a collapsed directory has git changes, the parent directory entry displays a git status indicator, signaling that something within it has changed. This helps the developer locate changed files without expanding every directory.

**Why this priority**: Without propagation, collapsed directories hide change information. This is a quality-of-life enhancement that makes the feature useful in large projects.

**Independent Test**: Can be tested by modifying a file inside a nested directory, collapsing that directory in the file browser, and verifying the parent directory shows a git status indicator.

**Acceptance Scenarios**:

1. **Given** a file with git changes is inside a collapsed directory, **When** the file browser renders, **Then** the parent directory entry displays a git status indicator.
2. **Given** all files in a directory are clean, **When** the file browser renders, **Then** the directory entry shows no git status indicator.

---

### Edge Cases

- What happens when the project is not a git repository? No git status indicators should appear, and no errors should be shown.
- What happens when git is not installed or not available on the system path? The file browser should render normally without git status indicators and without errors.
- What happens when a file has only diagnostic indicators but no git changes? Only the diagnostic indicator appears; no git status indicator is shown.
- What happens when a very large repository has thousands of changed files? Git status indicators should still render without noticeably blocking the editor.
- What happens when a file is deleted but still tracked by git? The file is not visible in the browser, so no indicator is needed.
- What happens when git status changes rapidly (e.g., during a rebase)? The display should debounce updates to avoid excessive re-rendering.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The file browser MUST display a git status indicator for files with unstaged changes.
- **FR-002**: The file browser MUST display a git status indicator for files with staged changes.
- **FR-003**: The file browser MUST display a git status indicator for files in an unmerged (conflict) state.
- **FR-004**: Each git status type (unstaged, staged, unmerged) MUST be represented by a visually distinct indicator.
- **FR-005**: Git status indicators MUST be positioned at the end of the file entry line, adjacent to any existing diagnostic indicator.
- **FR-006**: When a file has both diagnostic and git status indicators, both MUST be visible simultaneously on the same line.
- **FR-007**: Files with no git changes MUST NOT display a git status indicator.
- **FR-008**: Parent directories MUST display a git status indicator when any descendant file has git changes, even if the directory is collapsed.
- **FR-009**: Git status indicators MUST update when the user manually refreshes the file browser.
- **FR-010**: Git status indicators MUST update automatically when relevant file changes occur, using debounced rendering to avoid excessive redraws.
- **FR-011**: When the project is not a git repository, the file browser MUST render normally without git status indicators and without errors.
- **FR-012**: When a file has both staged and unstaged changes, the file browser MUST display indicators for both statuses.

### Key Entities

- **Git Status Indicator**: A visual marker shown at the end of a file browser entry line. Has a type (unstaged, staged, or unmerged), a display symbol, and a highlight group for coloring. Positioned adjacent to any diagnostic indicator on the same line.
- **File Entry**: A single line in the file browser representing a file or directory. May have zero or more associated indicators (diagnostic, git status).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can identify the git status of any visible file within 2 seconds of scanning the file browser.
- **SC-002**: All three git statuses (unstaged, staged, unmerged) are visually distinguishable from each other without relying on color alone (distinct symbols).
- **SC-003**: Git status indicators are visible alongside diagnostic indicators without either being obscured or truncated.
- **SC-004**: Git status indicators update within 2 seconds of a relevant change when the file browser is open.
- **SC-005**: The file browser remains responsive (no perceptible delay when navigating) in projects with up to 500 changed files.
- **SC-006**: Opening the file browser in a non-git project produces no errors and shows no git status indicators.

## Assumptions

- The existing git status model (which tracks unstaged, staged, and unmerged changes) will be reused and extended as needed.
- The existing diagnostic extmark rendering approach (virtual text at end of line) will serve as the pattern for git status indicators.
- Git status propagation to parent directories is already handled by the model layer, which includes ancestor directories in its tracking sets.
- The user's terminal and colorscheme support the highlight groups used for git status indicators. Fallback behavior for monochrome terminals is out of scope.
- Automatic refresh of git status may rely on manual refresh or editor events; filesystem watchers are out of scope for this feature.
