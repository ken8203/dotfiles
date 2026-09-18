---
name: new-stow-package
description: Scaffold a new GNU Stow package in this dotfiles repo and wire it into install.sh so it actually gets symlinked. Use when the user wants to add config for a new tool/app to the dotfiles (e.g. "add a stow package for nvim", "manage my wezterm config here", "create a new dotfiles package").
disable-model-invocation: true
---

# new-stow-package

This repo is managed with GNU Stow. Each top-level directory is a "package" whose
internal layout mirrors `$HOME`. Adding a package is **two coordinated changes** —
forgetting the second is the common failure mode:

1. Create the package directory with the file laid out at its `$HOME`-relative path.
2. Add the package name to the `stow ...` line in `install.sh` so it gets linked.

## Steps

1. **Pick the package name** (the tool name, e.g. `nvim`, `wezterm`).

2. **Create the directory tree** mirroring where the file lives under `$HOME`. Examples:
   - XDG config → `nvim/.config/nvim/init.lua`
   - home-dotfile → `wezterm/.wezterm.lua`
   - nested → `<pkg>/.config/<pkg>/config`

   Look at existing packages for the convention: most use `<pkg>/.config/<pkg>/...`, a few
   use bare home dotfiles (`tmux/.tmux.conf`, `vim/.vimrc`, `git/.gitconfig`).

3. **Wire it into `install.sh`.** Append the package name to the `PACKAGES` variable:
   ```sh
   PACKAGES="zsh git tmux starship vim bat revdiff hunk herdr agents"
   ```
   Keep the list on one line, space-separated. **This step is mandatory** — without it
   `./install.sh` will never stow the new package.

   If the package configures a GUI app that only runs on the Mac, add it to the
   `Darwin` branch below instead (`PACKAGES="$PACKAGES ghostty zed tty7"`), since
   Linux is installed as a headless box.

4. **Update `README.md`** if it has a Structure tree, adding the new package for documentation parity (optional but preferred).

5. **Offer to link it now** (don't run without asking):
   ```sh
   stow --target="$HOME" <pkg>
   ```
   Warn the user that if the target file already exists in `$HOME` un-symlinked, stow will
   refuse with a conflict — they may need to move/remove the existing file first.

## Verification
- `ls <pkg>` shows the expected tree.
- `grep '<pkg>' install.sh` confirms it's in `PACKAGES`.
