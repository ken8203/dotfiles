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

# No Homebrew formula yet, and brew bundle's npm entry can't run fnm's npm under its sanitized PATH.
if command -v agent-desktop >/dev/null 2>&1; then
  :
elif command -v npm >/dev/null 2>&1; then
  npm install -g agent-desktop
else
  echo "Skipping agent-desktop: npm not found, install a Node version with fnm first" >&2
fi
