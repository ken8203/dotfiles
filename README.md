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
| Stow packages | all | all but `ghostty`, `zed`, `tty7` |

Linux is assumed to be a headless dev box, so the GUI packages, the fonts and
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
├── herdr/.config/herdr/config.toml
├── hunk/.config/hunk/config.toml
├── revdiff/.config/revdiff/config
├── zed/.config/zed/{settings,keymap}.json
├── tty7/.config/tty7/{config.json,themes/}
├── agents/{.claude/CLAUDE.md, .codex/AGENTS.md, .agents/}
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

`simplify-review` and `hindsight-coding-agent` are not managed by the CLI and are
committed as plain files under `agents/.agents/skills/`. The CLI only links its own
installs into the agent directories, so the script symlinks anything in
`~/.agents/skills/` that the lock does not know about into `~/.claude/skills/`.

## Stack

- Terminal: [Ghostty](https://ghostty.org/)
- Shell: zsh
- Editor: vim, [Zed](https://zed.dev/)
- Prompt: [Starship](https://starship.rs/)
- Theme: [Nord](https://www.nordtheme.com/)
- Plugins: zsh-autosuggestions, zsh-syntax-highlighting
