#!/bin/sh
set -e

# cairn is private, so it is cloned over ssh rather than fetched with `go install`.
CAIRN_DIR="${CAIRN_DIR:-$HOME/me/cairn}"
BIN="$HOME/.local/bin"

if ! command -v go >/dev/null 2>&1; then
  echo "Skipping cairn: Go is not installed." >&2
  exit 0
fi
[ -d "$CAIRN_DIR" ] || git clone git@github.com:ken8203/cairn.git "$CAIRN_DIR"
make -C "$CAIRN_DIR" install PREFIX="$HOME/.local"

# Sessions started before the rename still call trail.
ln -sf cairn "$BIN/trail"
