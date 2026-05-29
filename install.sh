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
stow --target="$HOME" zsh git tmux ghostty starship vim bat revdiff zed hunk

# Install git hooks
echo "Installing git hooks..."
prek install

# Install Claude skills (managed by vercel-labs/skills)
echo "Installing skills..."
npx -y skills@latest add -g obra/superpowers \
  --skill brainstorming,writing-plans,executing-plans,subagent-driven-development,systematic-debugging,using-superpowers \
  --agent '*' -y
npx -y skills@latest add -g upstash/context7 --skill find-docs --agent '*' -y
npx -y skills@latest add -g vercel-labs/agent-browser --agent '*' -y
npx -y skills@latest add -g https://cli.sentry.dev --agent '*' -y

echo "Done! Restart your terminal."
