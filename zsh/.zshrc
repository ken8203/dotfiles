# Claude Code
export CLAUDE_CODE_NO_FLICKER=1
export CLAUDE_CODE_DISABLE_1M_CONTEXT=1

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Plugins (via Homebrew)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Report CWD via OSC 7 for terminal tab inheritance
_osc7_chpwd() {
  printf '\e]7;file://%s%s\a' "${HOST}" "${PWD}"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _osc7_chpwd
_osc7_chpwd

# Load paths and aliases
[[ -f ~/.paths ]] && source ~/.paths
[[ -f ~/.aliases ]] && source ~/.aliases

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Starship prompt (must be at the end)
eval "$(starship init zsh)"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# bun completions
[ -s "/Users/jaychung/.bun/_bun" ] && source "/Users/jaychung/.bun/_bun"
