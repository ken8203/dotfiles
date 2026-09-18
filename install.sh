#!/bin/sh
set -e

# Resolve the directory this script lives in, so it works regardless of where
# the dotfiles repo is checked out.
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

echo "Installing dotfiles for $OS..."

# GUI packages are macOS-only; Linux is treated as a headless dev box.
PACKAGES="zsh git tmux starship vim bat revdiff herdr agents"

case "$OS" in
  Darwin)
    PACKAGES="$PACKAGES ghostty"
    "$DOTFILES_DIR/scripts/packages-macos.sh"
    ;;
  Linux)
    "$DOTFILES_DIR/scripts/packages-linux.sh"
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

# Create symlinks
echo "Creating symlinks..."
cd "$DOTFILES_DIR"
# shellcheck disable=SC2086 # $PACKAGES is a deliberate argument list
stow --target="$HOME" $PACKAGES

# Install git hooks
if command -v prek >/dev/null 2>&1; then
  echo "Installing git hooks..."
  prek install
else
  echo "Skipping git hooks: prek is not installed." >&2
fi

# Install global skills (managed by skills.sh) from the stowed lock file
echo "Installing skills..."
"$DOTFILES_DIR/scripts/skills-restore.sh"

echo "Done! Restart your terminal."
