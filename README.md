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
├── revdiff/.config/revdiff/config
├── zed/.config/zed/{settings,keymap}.json
└── vim/.vimrc, .vim/
```

## Stack

- Terminal: [Ghostty](https://ghostty.org/)
- Shell: zsh
- Editor: vim, [Zed](https://zed.dev/)
- Prompt: [Starship](https://starship.rs/)
- Theme: [Nord](https://www.nordtheme.com/)
- Plugins: zsh-autosuggestions, zsh-syntax-highlighting
