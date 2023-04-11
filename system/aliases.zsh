alias ls='exa'
alias l='exa -lbF --git'
alias ll='exa -lbGF --git'
alias cat='bat'
alias mkdir='mkdir -p'
alias kc="kubectl"
alias reload="source $HOME/.zshrc && exec $SHELL -l"
alias plantuml="docker run -d -p 8080:8080 plantuml/plantuml-server:jetty"
alias offlinepg="gcloud compute ssh --zone asia-east1-a portal-os-login-1 --project dcard-production --tunnel-through-iap -- -L 127.0.0.1:5431:172.20.15.15:5432"

# Include custom aliases
if [[ -f ~/.aliases.local ]]; then
  source ~/.aliases.local
fi
