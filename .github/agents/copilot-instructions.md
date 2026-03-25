# tbrow Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-25

## Active Technologies
- Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9 + None beyond Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.loop`). Shell-outs to `git` for status detection. (002-git-status-extmark)
- N/A — reads git index/working tree via shell commands (002-git-status-extmark)
- Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9 + Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.fs`) (003-configurable-git-marks)

- Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9 + None beyond Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.loop`). Shell-outs to `ls` (filesystem) and `git` (status detection). (001-file-browser)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9

## Code Style

Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9: Follow standard conventions

## Recent Changes
- 003-configurable-git-marks: Added Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9 + Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.fs`)
- 002-git-status-extmark: Added Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9 + None beyond Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.loop`). Shell-outs to `git` for status detection.

- 001-file-browser: Added Lua (LuaJIT-compatible), targeting Neovim ≥ 0.9 + None beyond Neovim Lua stdlib (`vim.api`, `vim.fn`, `vim.loop`). Shell-outs to `ls` (filesystem) and `git` (status detection).

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
