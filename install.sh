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
stow zsh git tmux ghostty starship vim bat revdiff

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
