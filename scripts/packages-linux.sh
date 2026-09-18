#!/usr/bin/env bash
# Install the Linux counterpart of Brewfile on a headless dev box (Ubuntu/Debian).
#
# There is no `brew bundle` equivalent here: apt covers the basics, a few tools
# ship vendor apt repos, and the rest only publish upstream installers or GitHub
# releases. So the list lives here rather than in Brewfile, which stays macOS-only.
# Deliberately not installed on Linux: the casks, the fonts, and cloudflared.
#
# Past the apt step nothing aborts. Each tool is recorded on failure and reported
# at the end, so one dead URL or renamed asset doesn't cost the whole install.
set -uo pipefail

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
FAILED=()

# Where this script installs to. The shell running it predates those tools, so
# without this every re-run reinstalls them — and some upstream installers treat
# an existing install as an error.
PATH="$BIN_DIR:$HOME/.cargo/bin:$PATH"

case "$(uname -m)" in
  x86_64|amd64)  ARCH_GNU=x86_64;  ARCH_GO=amd64; ARCH_NODE=x64   ;;
  aarch64|arm64) ARCH_GNU=aarch64; ARCH_GO=arm64; ARCH_NODE=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

# Run a step, recording a failure instead of propagating it.
try() {
  local name=$1; shift
  printf '\n==> %s\n' "$name"
  "$@" && return 0
  echo "!! $name failed" >&2
  FAILED+=("$name")
  return 1
}

# Same, but skip entirely when the command is already on PATH.
need() {
  local cmd=$1; shift
  have "$cmd" || try "$cmd" "$@"
}

apt_install() { sudo apt-get update -qq && sudo apt-get install -y "$@"; }

# Register a vendor apt repo keyed by its signing key. Installing is left to the
# caller: `apt-get update` refreshes every configured source, so updating once
# per repo re-scans the ones already added.
apt_repo() {
  local name=$1 key_url=$2 line=$3
  local key="/etc/apt/keyrings/$name.gpg"
  sudo install -d -m 755 /etc/apt/keyrings || return 1
  curl -fsSL --retry 3 "$key_url" | sudo gpg --batch --yes --dearmor -o "$key" || return 1
  sudo chmod 644 "$key"
  echo "$line" | sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
}

# Install a release asset that is a bare binary.
fetch_bin() {
  local name=$1 url=$2 tmp rc
  tmp=$(mktemp) || return 1
  curl -fsSL --retry 3 -o "$tmp" "$url" && install -Dm755 "$tmp" "$BIN_DIR/$name"
  rc=$?
  rm -f "$tmp"
  return $rc
}

# Install one binary out of a .tar.gz release asset. $3 is its path in the archive.
fetch_tar() {
  local name=$1 url=$2 member=$3 dir rc
  dir=$(mktemp -d) || return 1
  curl -fsSL --retry 3 "$url" | tar -xz -C "$dir" && install -Dm755 "$dir/$member" "$BIN_DIR/$name"
  rc=$?
  rm -rf "$dir"
  return $rc
}

# --- apt ---------------------------------------------------------------------
printf '\n==> apt packages\n'
apt_install --no-install-recommends \
  zsh git tmux vim stow curl ca-certificates gnupg unzip xz-utils \
  build-essential jq ripgrep fd-find bat shellcheck \
  zsh-autosuggestions zsh-syntax-highlighting \
  || { echo "!! apt failed; stow and zsh are required to go on" >&2; exit 1; }

# Debian renames these to dodge clashes. Symlink the canonical names into
# ~/.local/bin, which sits ahead of /usr/bin on PATH, so scripts and tools find
# them too — an alias would only ever help an interactive shell.
have batcat && ln -sfn "$(command -v batcat)" "$BIN_DIR/bat"
have fdfind && ln -sfn "$(command -v fdfind)" "$BIN_DIR/fd"

# --- vendor apt repos --------------------------------------------------------
PKGS=()

# Register a vendor repo and queue its packages. Skipped when the tool is already
# installed, and the repo is left alone when some other source already serves that
# URI: a second entry for it with a different Signed-By makes apt refuse to read
# the whole source list, taking every other apt step down with it.
vendor() {
  local cmd=$1 name=$2 key_url=$3 uri=$4 line=$5; shift 5
  have "$cmd" && return 0
  if grep -rqsF "$uri" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    printf '\n==> %s repo already configured\n' "$name"
  else
    try "$name repo" apt_repo "$name" "$key_url" "$line" || return 1
  fi
  PKGS+=("$@")
}

vendor gh github-cli \
  https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  https://cli.github.com/packages \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/github-cli.gpg] https://cli.github.com/packages stable main" \
  gh

vendor eza gierens \
  https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  http://deb.gierens.de \
  "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  eza

# kubectl ships from the same repo, so gcloud and kubectl arrive together.
vendor gcloud google-cloud \
  https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  https://packages.cloud.google.com/apt \
  "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin kubectl

[ ${#PKGS[@]} -gt 0 ] && try "${PKGS[*]}" apt_install "${PKGS[@]}"

# --- upstream installers -----------------------------------------------------
need starship sh -c \
  "curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir '$BIN_DIR'"

need fnm sh -c \
  "curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir '$BIN_DIR' --skip-shell"

# cargo-dist installers; both land in ~/.cargo/bin or ~/.local/bin, already on PATH.
need prek sh -c \
  "curl -fsSL https://github.com/j178/prek/releases/latest/download/prek-installer.sh | sh"

need wt sh -c \
  "curl -fsSL https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh | sh"

need sentry-cli sh -c \
  "curl -fsSL https://sentry.io/get-cli/ | INSTALL_DIR='$BIN_DIR' bash"

need circleci sh -c \
  "curl -fsSL https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/main/install.sh | DESTDIR='$BIN_DIR' bash"

# --- GitHub releases ---------------------------------------------------------
need yq fetch_bin yq \
  "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$ARCH_GO"

# Takes whatever is current. `outpost-herdr` in .aliases instead pins the remote
# to the local Mac's build, because there the client and server have to match.
need herdr fetch_bin herdr \
  "https://github.com/herdrdev/herdr/releases/latest/download/herdr-linux-$ARCH_GNU"

need agent-browser fetch_bin agent-browser \
  "https://github.com/vercel-labs/agent-browser/releases/latest/download/agent-browser-linux-$ARCH_NODE"

need kubectx fetch_bin kubectx \
  "https://github.com/ahmetb/kubectx/releases/latest/download/kubectx"
need kubens fetch_bin kubens \
  "https://github.com/ahmetb/kubectx/releases/latest/download/kubens"

# The asset name carries the version, so resolve the tag first.
install_revdiff() {
  local ver
  ver=$(curl -fsSL --retry 3 https://api.github.com/repos/umputun/revdiff/releases/latest \
    | jq -re '.tag_name') || return 1
  fetch_tar revdiff \
    "https://github.com/umputun/revdiff/releases/download/$ver/revdiff_${ver#v}_linux_$ARCH_GO.tar.gz" \
    revdiff
}
need revdiff install_revdiff

# Ships `ast-grep` plus its `sg` shorthand in one zip.
install_ast_grep() {
  local dir rc
  dir=$(mktemp -d) || return 1
  curl -fsSL --retry 3 -o "$dir/ast-grep.zip" \
    "https://github.com/ast-grep/ast-grep/releases/latest/download/app-$ARCH_GNU-unknown-linux-gnu.zip" &&
    unzip -qo "$dir/ast-grep.zip" -d "$dir" &&
    install -Dm755 "$dir/ast-grep" "$BIN_DIR/ast-grep" &&
    install -Dm755 "$dir/sg" "$BIN_DIR/sg"
  rc=$?
  rm -rf "$dir"
  return $rc
}
need ast-grep install_ast_grep

# pnpm's standalone build needs its dist/ sibling, so unpack the whole thing into
# $PNPM_HOME rather than dropping a single binary in ~/.local/bin.
install_pnpm() {
  local dir="$HOME/.local/share/pnpm"
  mkdir -p "$dir" &&
    curl -fsSL --retry 3 \
      "https://github.com/pnpm/pnpm/releases/latest/download/pnpm-linux-$ARCH_NODE.tar.gz" \
      | tar -xz -C "$dir" &&
    chmod 755 "$dir/pnpm"
}
need pnpm install_pnpm

# --- login shell -------------------------------------------------------------
# Ubuntu defaults to bash, so none of the stowed zsh config would ever load.
# Compare against the passwd entry, not $SHELL, which is only this process's.
if have zsh && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  try "default shell -> zsh" sudo chsh -s "$(command -v zsh)" "$USER"
fi

# --- report ------------------------------------------------------------------
# Exit 0 even with failures: install.sh runs under `set -e`, and a missing
# optional tool shouldn't stop it from stowing the config.
if [ ${#FAILED[@]} -gt 0 ]; then
  printf '\n!! %d step(s) failed, install by hand:\n' "${#FAILED[@]}" >&2
  printf '   - %s\n' "${FAILED[@]}" >&2
else
  printf '\nAll packages installed.\n'
fi
