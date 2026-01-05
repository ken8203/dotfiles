#!/bin/sh
set -e

echo "Installing dotfiles..."

# Install Homebrew if not exists
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install dependencies
echo "Installing dependencies..."
brew bundle --file=~/dotfiles/Brewfile

# Create symlinks
echo "Creating symlinks..."
cd ~/dotfiles
stow zsh git tmux ghostty starship vim

echo "Done! Restart your terminal."
