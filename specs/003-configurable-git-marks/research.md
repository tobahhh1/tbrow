# Research: Configurable Git Marks

**Feature**: 003-configurable-git-marks  
**Date**: 2026-03-25

## R1: Git Command for Untracked Files

**Decision**: Use `git ls-files --others --exclude-standard` to list untracked files.

**Rationale**: This is the standard git plumbing command for listing files present in the working tree that are not tracked by git. The `--exclude-standard` flag respects `.gitignore`, `.git/info/exclude`, and the global exclude file, which satisfies FR-012 (ignored files must not be marked as untracked). The command returns paths relative to the repo root, consistent with the existing `git diff --name-only` commands used for staged/unstaged/unmerged.

**Alternatives considered**:
- `git status --porcelain`: Provides untracked files (lines starting with `??`), but requires parsing a more complex output format. The existing model uses `git diff --name-only` for the other statuses, and `git ls-files` keeps the output format consistent (plain path list, one per line).
- `git status --short`: Same parsing complexity as `--porcelain`, less machine-friendly.

## R2: Default Color Values for Highlight Groups

**Decision**: Define highlight groups with explicit `fg` color values rather than linking to Diagnostic groups.

- `TbrowGitStaged`: `fg = "#608b4e"` (muted green, readable on dark and light backgrounds)
- `TbrowGitUnstaged`: `fg = "#d7875f"` (dark orange, 256-color compatible: `173`)
- `TbrowGitUntracked`: `fg = "#d7875f"` (same dark orange as unstaged)
- `TbrowGitUnmerged`: `fg = "#f44747"` (red, consistent with conflict/error semantics)

**Rationale**: The spec requires green/staged, dark orange/modified+untracked, red/unmerged. The previous implementation linked to `DiagnosticInfo` (typically blue/cyan), `DiagnosticWarn` (typically yellow), and `DiagnosticError` (typically red). These didn't match conventional git color semantics. Explicit `fg` values with `default = true` allow colorschemes to override them while ensuring sensible out-of-box colors. The dark orange value `#d7875f` maps to xterm-256 color 173, ensuring good terminal compatibility.

**Alternatives considered**:
- Linking to different semantic groups (e.g., `DiffAdd`, `DiffChange`, `DiffDelete`): These groups vary widely across colorschemes and don't reliably produce the requested green/orange/red palette.
- Using only 256-color codes: Would limit GUI Neovim users. Using hex values with 256-color-compatible choices provides the best coverage.

## R3: Configuration Mechanism for Mark Text and Colors

**Decision**: Accept a `git_marks` table in `setup()` opts, store it as `vim.g.tbrow_git_marks`, and read it in the view layer at render time.

**Configuration shape**:
```lua
require("tbrow"):setup({
  git_marks = {
    staged    = { text = " S", hl = { fg = "#608b4e" } },
    unstaged  = { text = " M", hl = { fg = "#d7875f" } },
    untracked = { text = " ?", hl = { fg = "#d7875f" } },
    unmerged  = { text = " U", hl = { fg = "#f44747" } },
  }
})
```

Each key is optional. Each sub-field (`text`, `hl`) is optional. Missing keys or fields fall back to defaults. The `hl` value is passed directly to `vim.api.nvim_set_hl()` as the opts table, so users can use any valid highlight attributes (`fg`, `bg`, `bold`, `link`, etc.).

**Rationale**: This follows the existing pattern established by `icons` (a table stored in `vim.g.tbrow_icons`, read at render time via a getter that checks user config then falls back to defaults). Using `vim.g` is consistent with all other tbrow options. Accepting a full highlight opts table (not just a color string) gives power users flexibility to set `bold`, `bg`, `italic`, etc., while keeping the simple case simple (just provide `fg`).

**Alternatives considered**:
- Separate `git_mark_colors` and `git_mark_text` options: More verbose, no clear benefit over a single nested table.
- Requiring users to call `nvim_set_hl` directly: Already possible (highlight groups are `default = true`), but less discoverable. The `setup()` option provides a first-class, documented configuration path.
- Storing config in a module-level variable instead of `vim.g`: Would break the established pattern. All tbrow options use `vim.g`.

## R4: Default Mark Text for Untracked Files

**Decision**: Use `" ?"` as the default untracked mark text.

**Rationale**: The `?` symbol is universally associated with untracked files in git (e.g., `??` in `git status --short`). It is distinct from `S` (staged), `M` (modified), and `U` (unmerged). The leading space is consistent with the existing mark format (all marks start with a space for visual separation from the filename).

**Alternatives considered**:
- `" N"` (new): Less immediately recognizable as "untracked" to git users.
- `" A"` (added): Conflicts with the meaning of "staged for addition" in some git UIs.
- `" ?"` with double question mark `" ??"`: Consistent with `git status` but takes more horizontal space than other single-character marks.
