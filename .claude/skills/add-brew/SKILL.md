---
name: add-brew
description: Add a Homebrew formula or cask to this repo's Brewfile, placing it in the correct category section. Use when the user wants to add a package, formula, cask, tap, or CLI tool to the Brewfile (e.g. "add circleci to the brewfile", "install ripgrep via brew here").
disable-model-invocation: true
---

# add-brew

Add a Homebrew dependency to `Brewfile` (repo root) in a consistent, idiomatic way.

## Steps

1. **Identify the package.** Resolve the name the user gave to the actual Homebrew token. If unsure whether it's a formula or cask, check:
   ```sh
   brew info <name>
   ```
   GUI apps, fonts, and some CLI tools (e.g. `gcloud-cli`) are casks; most CLI tools are formulae.

2. **Read `Brewfile`** and find the matching category comment. Existing sections are organised by purpose, e.g.:
   - `# CLI tools` — general command-line utilities
   - `# Shell` — shell/prompt/tmux
   - `# Cloud` — cloud + infra CLIs
   - `# Observability`
   - `# Fonts`
   - `# Git hooks`, `# Git worktree management`, `# Runtime management`, `# Diff review`, `# Dotfiles management`

   Pick the section that best fits. If nothing fits, add a new `# <Category>` comment block near related entries rather than dumping it at the end.

3. **Choose the right directive:**
   - Formula → `brew "<name>"`
   - Cask → `cask "<name>"`
   - Needs a third-party tap → add `tap "<owner>/<repo>"` above it and use the fully-qualified `brew "<owner>/<repo>/<name>"` (see the `revdiff` / `sentry` entries for the pattern).

4. **Insert** the line at the end of the chosen section, matching surrounding quoting/indentation. Don't reorder unrelated lines.

5. **Confirm** to the user what was added and to which section. Don't run `brew bundle` unless asked.

## Notes
- One dependency per line; keep the existing `brew "x"` quoting style.
- Avoid duplicates — grep the file for the token first.
