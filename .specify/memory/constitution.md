<!--
  Sync Impact Report
  ==================
  Version change: 0.0.0 → 1.0.0 (initial adoption)
  Modified principles: N/A (first version)
  Added sections:
    - Core Principles (4): MVC Separation, Immutable State,
      Native Buffer Citizenship, API-First Surface
    - Architecture Constraints
    - Development Workflow
    - Governance
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ no changes needed
    - .specify/templates/spec-template.md ✅ no changes needed
    - .specify/templates/tasks-template.md ✅ no changes needed
    - .specify/templates/checklist-template.md ✅ no changes needed
    - .specify/templates/agent-file-template.md ✅ no changes needed
  Follow-up TODOs: None
-->

# Tbrow Constitution

## Core Principles

### I. MVC Separation

Every module MUST belong to exactly one of Model, View, Controller,
or API. Cross-layer imports follow a strict dependency direction:

- **Controller → Model** — controllers call model functions to
  produce new state.
- **Controller → View** — controllers pass model state to view
  functions for rendering.
- **View → Model (read-only)** — views MAY read model types to
  render them but MUST NOT mutate or construct model state.
- **API → Controller** — the public API delegates to controller
  logic; it MUST NOT reach into model or view internals directly.
- **Model → nothing** — models MUST NOT import from view,
  controller, or API layers.
- **Utils** are leaf modules: they MUST NOT import from any layer.

File placement enforces this rule:
`lua/model/`, `lua/view/`, `lua/controller/`, `lua/api/`,
`lua/utils/`.

**Rationale**: Strict layering prevents circular dependencies,
keeps rendering logic replaceable, and makes each layer
independently testable.

### II. Immutable State

All state transitions MUST be performed by returning new state
objects. Direct mutation of `ModelState`, `ViewState`, `FileGraph`,
or `DiagnosticStore` fields after construction is prohibited.

- State update functions MUST accept the current state and return
  a new state value (e.g., `with_file_expanded(state, path)` →
  new `ModelState`).
- Shallow copies via utility helpers are the approved mechanism
  for deriving new state.
- The global registry (`TbrowBufnrToInstance`) is the single
  point of assignment; only controllers MAY write to it, and only
  by replacing the entire `{model_state, view_state}` pair.
- Side effects (filesystem reads, Neovim API calls) MUST be
  isolated at the boundary of state transitions, never embedded
  inside model constructors.

**Rationale**: Immutable updates eliminate a class of aliasing
bugs, make undo/redo feasible, and keep the render path
predictable — draw is always a pure function of state.

### III. Native Buffer Citizenship

The tbrow buffer MUST behave like a first-class Neovim buffer with
respect to cursor movement and built-in motions.

- Standard Vim motions (`hjkl`, `gg`, `G`, `/`, `?`, marks,
  counts, `{`, `}`, etc.) MUST remain fully operational. No
  keymap set by tbrow MAY shadow or disable a navigation motion.
- Tbrow keymaps MUST be limited to action bindings that do not
  conflict with motion keys (e.g., `<CR>`, `p`, `P`, `yd`, `yc`,
  `<C-l>`). Adding a new binding requires confirming it does not
  override a default Vim motion.
- The buffer MUST be `readonly`, `nomodifiable`, `buftype=nofile`,
  and `filetype=tbrow`. Writes are allowed only inside the
  guarded `write_to_buf` helper that temporarily unlocks the
  buffer.
- Cursor position is the sole mechanism for determining which
  file an action targets; view state MUST maintain accurate
  line ↔ filepath mappings at all times.

**Rationale**: Users choose a Vim-native file browser specifically
so their muscle memory transfers. Broken motions undermine the
core value proposition.

### IV. API-First Surface

Every capability intended for external consumption MUST be
exposed through `lua/api/` and re-exported via the top-level
`require("tbrow").api` table.

- Public API functions MUST accept explicit parameters (e.g.,
  `winnr`) rather than relying on implicit global context.
- Return values MUST be plain Lua types (`string`, `nil`,
  `table`) — no internal class instances may leak across the API
  boundary.
- API functions MUST be safe to call from any context (autocommands,
  other plugins, user `init.lua`). They MUST NOT throw on invalid
  input; return `nil` or a descriptive error value instead.
- Breaking changes to a public API function require a MAJOR
  version bump of this constitution and explicit migration notes.

**Rationale**: An ergonomic, stable API lets other Lua code (file
pickers, statuslines, custom workflows) integrate with tbrow
without coupling to its internals.

## Architecture Constraints

- **Language**: Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9.
- **External dependencies**: None beyond the Neovim Lua stdlib
  (`vim.api`, `vim.fn`, `vim.loop`). Shell-outs (e.g., `ls`) are
  acceptable only inside model boundary functions.
- **Global state**: The only permitted global is
  `TbrowBufnrToInstance`. New globals require constitution
  amendment.
- **Rendering**: Stack-based iteration MUST be used for tree
  traversal to avoid Lua recursion limits on deep directory trees.
- **Performance**: Diagnostic refreshes MUST be debounced.
  Full-tree re-renders MUST avoid redundant filesystem reads
  when the tree structure has not changed.

## Development Workflow

- Every pull request MUST identify which constitution principles
  it touches and confirm compliance.
- New keymaps MUST include a justification that no default Vim
  motion is shadowed.
- New public API functions MUST include a usage example in the PR
  description.
- Refactors that move code between layers MUST be isolated
  commits with no behavioral changes mixed in.

## Governance

This constitution is the authoritative guide for architectural
decisions in the tbrow project. It supersedes ad-hoc conventions
and informal agreements.

- **Amendments** require updating this file, incrementing the
  version, and recording the change in the Sync Impact Report
  comment at the top.
- **Versioning** follows Semantic Versioning:
  - MAJOR — principle removed or redefined incompatibly.
  - MINOR — new principle or section added, material expansion.
  - PATCH — clarifications, typo fixes, non-semantic rewording.
- **Compliance** — every feature spec and implementation plan
  MUST include a Constitution Check section confirming alignment
  with these principles.

**Version**: 1.0.0 | **Ratified**: 2026-03-25 | **Last Amended**: 2026-03-25
