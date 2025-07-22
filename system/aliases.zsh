alias ls='eza'
alias l='eza -lbF --git'
alias ll='eza -lbGF --git'
alias cat='bat'
alias mkdir='mkdir -p'
alias kc="kubectl"
alias kcx="kubectx"
alias kcns="kubens"
alias reload="source $HOME/.zshrc && exec $SHELL -l"
alias plantuml="docker run -d -p 8080:8080 plantuml/plantuml-server:jetty"
alias offlinepg="kubectl port-forward deploy/db-auth-proxy 5431:5432"
alias gal="gcloud auth login --update-adc"
alias pn="pnpm"

kcexec() {
  kubectl exec -it $1 -- sh
}

# Include custom aliases
if [[ -f ~/.aliases.local ]]; then
  source ~/.aliases.local
fi
