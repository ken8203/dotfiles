alias ls='exa'
alias l='exa -lbF --git'
alias ll='exa -lbGF --git'
alias cat='bat'
alias mkdir='mkdir -p'
alias kc="kubectl"

# Include custom aliases
if [[ -f ~/.aliases.local ]]; then
  source ~/.aliases.local
fi
