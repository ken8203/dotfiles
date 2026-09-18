#!/bin/sh
# Install everything in Brewfile, bootstrapping Homebrew if it isn't there yet.
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Installing dependencies..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
