# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Install

```bash
git clone https://github.com/ken8203/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

## Usage

```bash
cd ~/dotfiles

# Link all packages
./install.sh

# Link single package
stow zsh

# Unlink package
stow -D zsh

# Re-link package
stow --restow zsh
```

## Structure

```
~/dotfiles/
├── zsh/
│   ├── .zshrc
│   ├── .aliases
│   └── .paths
├── git/.gitconfig, .gitignore
├── tmux/.tmux.conf
├── ghostty/.config/ghostty/config
├── starship/.config/starship.toml
└── vim/.vimrc, .vim/
```

## Stack

- Terminal: [Ghostty](https://ghostty.org/)
- Shell: zsh
- Editor: vim
- Prompt: [Starship](https://starship.rs/)
- Theme: [Nord](https://www.nordtheme.com/)
- Plugins: zsh-autosuggestions, zsh-syntax-highlighting
