#!/bin/sh
set -e

# Resolve the directory this script lives in, so it works regardless of where
# the dotfiles repo is checked out.
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles..."

# Install Homebrew if not exists
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install dependencies
echo "Installing dependencies..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# Create symlinks
echo "Creating symlinks..."
cd "$DOTFILES_DIR"
stow --target="$HOME" zsh git tmux ghostty starship vim bat revdiff zed hunk herdr agents tty7

# Install git hooks
echo "Installing git hooks..."
prek install

# Install global skills (managed by skills.sh) from the stowed lock file
echo "Installing skills..."
"$DOTFILES_DIR/scripts/skills-restore.sh"

echo "Done! Restart your terminal."
