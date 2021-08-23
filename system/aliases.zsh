alias ls='exa'
alias l='exa -lbF --git'
alias ll='exa -lbGF --git'
alias cat='bat'
alias mkdir='mkdir -p'
alias kc="kubectl"
alias reload="source $HOME/.zshrc && exec $SHELL -l"
alias plantuml="docker run -d -p 8080:8080 plantuml/plantuml-server:jetty"

# Include custom aliases
if [[ -f ~/.aliases.local ]]; then
  source ~/.aliases.local
fi
