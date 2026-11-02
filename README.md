# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Install

```bash
# Clone anywhere; install.sh resolves its own location and stows into $HOME.
git clone https://github.com/ken8203/dotfiles.git
cd dotfiles && ./install.sh
```

## Usage

```bash
# Run from the repo directory (wherever you cloned it).

# Link all packages
./install.sh

# Link single package
stow --target="$HOME" zsh

# Unlink package
stow --target="$HOME" -D zsh

# Re-link package
stow --target="$HOME" --restow zsh
```

## Platforms

`install.sh` branches on `uname -s`:

| | macOS | Linux |
|---|---|---|
| Packages | `Brewfile` via `scripts/packages-macos.sh` | `scripts/packages-linux.sh` (apt + vendor repos + upstream releases) |
| Stow packages | all | all but `ghostty` |

Linux is assumed to be a headless dev box, so the GUI package, the fonts and
`cloudflared` are skipped. `Brewfile` stays macOS-only — the Linux list lives in
`scripts/packages-linux.sh` because it has no single source: apt covers the
basics, `gh`/`eza`/`gcloud` ship vendor apt repos, and the rest only publish
upstream installers or GitHub releases. Only the apt step is fatal there, since
`stow` comes from it; past that each tool is reported at the end and installed
by hand.

The zsh config mostly doesn't ask which OS it is on — it asks whether the
directory or the binary is there, so a path is only added when it exists and an
alias only when its target does. `$OSTYPE` is left for the one thing that really
is OS-dependent, `$PNPM_HOME`. Debian's renamed `batcat`/`fdfind` are fixed at
the source instead: `packages-linux.sh` symlinks the canonical names into
`~/.local/bin`, so scripts and tools see them too, not just interactive shells.

## Structure

```
dotfiles/
├── zsh/
│   ├── .zshrc
│   ├── .aliases
│   └── .paths
├── git/.gitconfig, .gitignore
├── tmux/.tmux.conf
├── ghostty/.config/ghostty/config
├── starship/.config/starship.toml
├── bat/.config/bat/config
├── revdiff/.config/revdiff/config
├── agents/{.claude/CLAUDE.md, .codex/AGENTS.md, .agents/}
├── trail/.local/bin/{trail, pr-shim, gh, git}
├── rex/.config/rex/init.lua
├── vim/.vimrc, .vim/
└── scripts/packages-{macos,linux}.sh, skills-restore.sh
```

## Skills

Global agent skills are installed by [skills.sh](https://www.skills.sh/) into
`~/.agents/skills/`, which it symlinks into each agent's own directory
(`~/.claude/skills/` and friends). The manifest it keeps there,
`~/.agents/.skill-lock.json`, is stowed from the `agents` package so it travels
with this repo.

The CLI's `experimental_install` only restores a project-level `skills-lock.json`,
so `scripts/skills-restore.sh` replays the global lock through `skills add -g`
instead. `install.sh` runs it; run it directly after editing the lock by hand:

```bash
./scripts/skills-restore.sh
```

It also strips `disable-model-invocation: true` from the handful of skills that
should stay model-invocable — see the list at the top of the script.

`simplify-review`, `rethink`, and `outpost-delegate` are not managed by the CLI and are committed
as plain files under `agents/.agents/skills/`. The CLI only links its own installs into the agent
directories, so the script symlinks anything in `~/.agents/skills/` that the lock
does not know about into `~/.claude/skills/`, leaving real directories alone.

Hindsight is not in here at all — its own installer owns `~/.hindsight`, the agent
hooks, and its skill in both `~/.agents/skills/` and `~/.claude/skills/`. Stowing a
copy of that skill only collides with it. Install it per machine with:

```bash
npx @vectorize-io/hindsight-coding-agents install claude-code --server self-hosted --api-url https://hindsight.dcard.io
npx @vectorize-io/hindsight-coding-agents install codex --server self-hosted --api-url https://hindsight.dcard.io
```

## Trail

Work here often spans a chain of PRs across repos (an API change in one, its client in
another) plus steps that aren't PRs at all, such as a release or a feature flag. A
trail is that chain as an ordered checklist, shared by every Rex pane working on it,
so any pane shows where the work stands. Trails are Markdown files in
`~/.local/state/trail/trails/`:

```markdown
# client-call

- [ ] Dcard/GNTC#13760
- [ ] Dcard/Dock#812
- [ ] release EntryDesk api
- [ ] staging: enable CLIENT_CALL_ACCEPT_EXECUTOR_ID

## Notes

- 11-02 #13760 waiting on review
```

PR steps count as done once GitHub says merged or closed; free-text steps are ticked
with `trail done <n>`. A PR whose base branch is another step's head is shown as
stacked, with a hint once that base has merged. `trail use <name>` attaches a pane;
`trail ls` lists every trail with its next step. See `trail --help` for the rest.

`pr-shim` is linked into `~/.local/bin` as both `gh` and `git`, shadowing Homebrew's.
When an agent (stdout not a TTY, `REX_BLOCK` set) opens a PR, pushes a branch that has
one, or runs `gh pr checkout|comment|review|edit|merge|…`, it records the PR for that
pane. PRs the agent authors are appended to the pane's trail, and a pane touching a PR
that is already on a trail joins it. Interactive runs pass straight through. Codex runs
commands in a login shell, where `/etc/zprofile`'s `path_helper` moves
`/opt/homebrew/bin` ahead again, so the local `~/.zprofile` (not stowed) has to
re-prepend `~/.local/bin` last.

Press <kbd>Ctrl</kbd>+<kbd>Cmd</kbd>+<kbd>P</kbd> in a pane (the `trail` action in
`rex/.config/rex/init.lua`, also "Toggle Trail" in the command palette) to float the
trail over it. <kbd>1</kbd>–<kbd>9</kbd> opens a PR or ticks a step, <kbd>e</kbd> edits
the trail, <kbd>r</kbd> refreshes, and <kbd>q</kbd> or the shortcut again closes it.

Claude Code can show the trail's progress and next step in its statusline.
`~/.claude/settings.json` is not stowed, so append the segment to whatever
`statusLine.command` is already there:

```json
"statusLine": { "type": "command", "command": "<existing command>; ~/.local/bin/trail statusline" }
```

## Stack

- Terminal: [Ghostty](https://ghostty.org/), [Herdr](https://herdr.dev/), [Rex](https://www.superlogical.com/rex)
- Shell: zsh
- Editor: vim
- Prompt: [Starship](https://starship.rs/)
- Theme: [Nord](https://www.nordtheme.com/)
- Plugins: zsh-autosuggestions, zsh-syntax-highlighting
