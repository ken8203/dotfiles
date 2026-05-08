#!/usr/bin/env bash
# user override of revdiff launcher (synced from upstream v0.8.9)
# only diff vs bundled: cmux split direction `down` -> `right`
# re-sync source: ~/.claude/plugins/cache/revdiff/revdiff/<ver>/.claude-plugin/skills/revdiff/scripts/launch-revdiff.sh

set -euo pipefail

REVDIFF_BIN=$(command -v revdiff 2>/dev/null || true)
if [ -z "$REVDIFF_BIN" ]; then
    echo "error: revdiff not found in PATH" >&2
    echo "install: brew install umputun/apps/revdiff (or download from https://github.com/umputun/revdiff/releases)" >&2
    exit 1
fi

TMPBASE="${TMPDIR:-/tmp}"
OUTPUT_FILE=$(mktemp "$TMPBASE/revdiff-output-XXXXXX")
trap 'rm -f "$OUTPUT_FILE"' EXIT

sq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

REVDIFF_CMD="$(sq "$REVDIFF_BIN")"
if [ -n "${REVDIFF_CONFIG:-}" ] && [ -f "$REVDIFF_CONFIG" ]; then
    REVDIFF_CMD="$REVDIFF_CMD $(sq "--config=$REVDIFF_CONFIG")"
fi
REVDIFF_CMD="$REVDIFF_CMD $(sq "--output=$OUTPUT_FILE")"
for arg in "$@"; do
    REVDIFF_CMD="$REVDIFF_CMD $(sq "$arg")"
done

ENV_PREFIX=""
for _name in EDITOR VISUAL; do
    if [ "${!_name+x}" = x ]; then
        ENV_PREFIX="$ENV_PREFIX $(sq "${_name}=${!_name}")"
    fi
done
unset _name
if [ -n "$ENV_PREFIX" ]; then
    REVDIFF_CMD="/usr/bin/env$ENV_PREFIX $REVDIFF_CMD"
fi

CWD="$(pwd)"

DIR_NAME=$(basename "$CWD")
TITLE_REF=""
SKIP_NEXT=0
for arg in "$@"; do
    if [ "$SKIP_NEXT" -eq 1 ]; then SKIP_NEXT=0; continue; fi
    case "$arg" in
        -o|--output) SKIP_NEXT=1 ;;
        --output=*) ;;
        -*) ;;
        *) TITLE_REF="$arg"; break ;;
    esac
done
OVERLAY_TITLE="rd: ${DIR_NAME}${TITLE_REF:+ [$TITLE_REF]}"

POPUP_W="${REVDIFF_POPUP_WIDTH:-90%}"
POPUP_H="${REVDIFF_POPUP_HEIGHT:-90%}"

if [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
    TMUX_ARGS=(tmux display-popup -E -w "$POPUP_W" -h "$POPUP_H")
    if [[ "$(tmux -V 2>/dev/null)" =~ ([0-9]+)\.([0-9]+) ]]; then
        if [ "${BASH_REMATCH[1]}" -gt 3 ] || { [ "${BASH_REMATCH[1]}" -eq 3 ] && [ "${BASH_REMATCH[2]}" -ge 3 ]; }; then
            TMUX_ARGS+=(-T " $OVERLAY_TITLE ")
        fi
    fi
    TMUX_ARGS+=(-d "$CWD" -- sh -c "$REVDIFF_CMD")
    "${TMUX_ARGS[@]}"
    cat "$OUTPUT_FILE"
    exit 0
fi

if [ -n "${ZELLIJ:-}" ] && command -v zellij >/dev/null 2>&1; then
    SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
    rm -f "$SENTINEL"

    LAUNCH_SCRIPT=$(mktemp "$TMPBASE/revdiff-launch-XXXXXX")
    trap 'rm -f "$OUTPUT_FILE" "$SENTINEL" "$LAUNCH_SCRIPT"' EXIT
    cat > "$LAUNCH_SCRIPT" <<LAUNCHER
#!/bin/sh
$REVDIFF_CMD; touch $(sq "$SENTINEL")
LAUNCHER
    chmod +x "$LAUNCH_SCRIPT"

    ZELLIJ_W="${POPUP_W%%%}"
    ZELLIJ_H="${POPUP_H%%%}"
    zellij run --floating --close-on-exit \
        --width "$ZELLIJ_W" --height "$ZELLIJ_H" \
        --name "$OVERLAY_TITLE" --cwd "$CWD" \
        -- "$LAUNCH_SCRIPT" >/dev/null 2>&1

    while [ ! -f "$SENTINEL" ]; do
        sleep 0.3
    done
    rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
    cat "$OUTPUT_FILE"
    exit 0
fi

KITTY_SOCK="${KITTY_LISTEN_ON:-}"
if [ -n "$KITTY_SOCK" ] && command -v kitty >/dev/null 2>&1; then
    SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
    rm -f "$SENTINEL"

    KITTY_ARGS=(kitty @ --to "$KITTY_SOCK" launch --type=overlay --title="$OVERLAY_TITLE" --cwd=current)
    if [ -n "${KITTY_WINDOW_ID:-}" ]; then
        KITTY_ARGS+=(--match "window_id:${KITTY_WINDOW_ID}")
    fi
    KITTY_ARGS+=(sh -c "cd $(sq "$CWD") && $REVDIFF_CMD; touch $(sq "$SENTINEL")")

    "${KITTY_ARGS[@]}" >/dev/null 2>&1

    while [ ! -f "$SENTINEL" ]; do
        sleep 0.3
    done
    rm -f "$SENTINEL"
    cat "$OUTPUT_FILE"
    exit 0
fi

if [ -n "${WEZTERM_PANE:-}" ]; then
    WEZTERM_CLI=()
    if command -v wezterm >/dev/null 2>&1; then
        WEZTERM_CLI=(wezterm cli)
    elif command -v kaku >/dev/null 2>&1; then
        WEZTERM_CLI=(kaku cli)
    fi

    if [ ${#WEZTERM_CLI[@]} -gt 0 ]; then
        SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
        rm -f "$SENTINEL"

        WEZTERM_PCT="${REVDIFF_POPUP_HEIGHT:-90%}"
        WEZTERM_PCT="${WEZTERM_PCT%%%}"
        "${WEZTERM_CLI[@]}" split-pane --bottom --percent "$WEZTERM_PCT" \
            --pane-id "$WEZTERM_PANE" --cwd "$CWD" -- sh -c "$REVDIFF_CMD; touch $(sq "$SENTINEL")" >/dev/null 2>&1

        while [ ! -f "$SENTINEL" ]; do
            sleep 0.3
        done
        rm -f "$SENTINEL"
        cat "$OUTPUT_FILE"
        exit 0
    fi
fi

# cmux: split right (user override; bundled default is `down`)
if [ -n "${CMUX_SURFACE_ID:-}" ] && command -v cmux >/dev/null 2>&1; then
    SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
    rm -f "$SENTINEL"

    LAUNCH_SCRIPT=$(mktemp "$TMPBASE/revdiff-launch-XXXXXX")
    trap 'rm -f "$OUTPUT_FILE" "$SENTINEL" "$LAUNCH_SCRIPT"' EXIT
    cat > "$LAUNCH_SCRIPT" <<LAUNCHER
#!/bin/sh
$REVDIFF_CMD; touch $(sq "$SENTINEL")
LAUNCHER
    chmod +x "$LAUNCH_SCRIPT"

    CMUX_NEW=$(cmux new-split right 2>&1) || true
    CMUX_SURF=$(echo "$CMUX_NEW" | grep -o 'surface:[0-9]*' | head -1 || true)

    if [ -z "$CMUX_SURF" ]; then
        echo "error: cmux new-split did not return a surface id: $CMUX_NEW" >&2
        exit 1
    fi

    cmux send --surface "$CMUX_SURF" "exec $(sq "$LAUNCH_SCRIPT")\n" >/dev/null 2>&1

    while [ ! -f "$SENTINEL" ]; do
        sleep 0.3
    done
    cmux close-surface --surface "$CMUX_SURF" 2>/dev/null || true
    rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
    cat "$OUTPUT_FILE"
    exit 0
fi

if [ "${TERM_PROGRAM:-}" = "ghostty" ] && command -v osascript >/dev/null 2>&1; then

    SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
    rm -f "$SENTINEL"

    LAUNCH_SCRIPT=$(mktemp "$TMPBASE/revdiff-launch-XXXXXX")
    trap 'rm -f "$OUTPUT_FILE" "$SENTINEL" "$LAUNCH_SCRIPT"' EXIT
    cat > "$LAUNCH_SCRIPT" <<LAUNCHER
#!/bin/sh
$REVDIFF_CMD; touch $(sq "$SENTINEL")
LAUNCHER
    chmod +x "$LAUNCH_SCRIPT"

    if ! GHOSTTY_TERM_ID=$(osascript - "$LAUNCH_SCRIPT" "$CWD" <<'APPLESCRIPT'
on run argv
    set launchScript to item 1 of argv
    set cwd to item 2 of argv
    tell application "Ghostty"
        set cfg to new surface configuration
        set command of cfg to launchScript
        set initial working directory of cfg to cwd
        set wait after command of cfg to false
        set ft to focused terminal of selected tab of front window
        set newTerm to split ft direction down with configuration cfg
        perform action "toggle_split_zoom" on newTerm
        return id of newTerm
    end tell
end run
APPLESCRIPT
    ); then
        rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
        exit 1
    fi

    while [ ! -f "$SENTINEL" ]; do
        sleep 0.3
    done
    osascript - "$GHOSTTY_TERM_ID" <<'APPLESCRIPT' 2>/dev/null
on run argv
    tell application "Ghostty" to close terminal id (item 1 of argv)
end run
APPLESCRIPT
    rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
    cat "$OUTPUT_FILE"
    exit 0
fi

if [ -n "${ITERM_SESSION_ID:-}" ] && command -v osascript >/dev/null 2>&1; then
    SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
    rm -f "$SENTINEL"

    LAUNCH_SCRIPT=$(mktemp "$TMPBASE/revdiff-launch-XXXXXX")
    trap 'rm -f "$OUTPUT_FILE" "$SENTINEL" "$LAUNCH_SCRIPT"' EXIT
    cat > "$LAUNCH_SCRIPT" <<LAUNCHER
#!/bin/sh
cd "\$1" && $REVDIFF_CMD; touch "\$2"
LAUNCHER
    chmod +x "$LAUNCH_SCRIPT"

    ITERM_UUID="${ITERM_SESSION_ID##*:}"

    ITERM_NEW_SESSION=$(osascript - "$ITERM_UUID" "$LAUNCH_SCRIPT" "$CWD" "$SENTINEL" <<'APPLESCRIPT' 2>&1
on run argv
    set targetId to item 1 of argv
    set launchScript to item 2 of argv
    set cwd to item 3 of argv
    set sentinel to item 4 of argv
    set cmd to quoted form of launchScript & " " & quoted form of cwd & " " & quoted form of sentinel
    tell application id "com.googlecode.iterm2"
        repeat with w in windows
            repeat with t in tabs of w
                repeat with s in sessions of t
                    if id of s is targetId then
                        set colCount to columns of s
                        set rowCount to rows of s
                        tell s
                            if colCount >= 160 and colCount > (rowCount * 2) then
                                set newSession to split vertically with same profile command cmd
                            else
                                set newSession to split horizontally with same profile command cmd
                            end if
                        end tell
                        return id of newSession
                    end if
                end repeat
            end repeat
        end repeat
    end tell
    error "session not found: " & targetId
end run
APPLESCRIPT
    ) || {
        echo "error: failed to open iTerm2 split via osascript: $ITERM_NEW_SESSION" >&2
        rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
        exit 1
    }

    while [ ! -f "$SENTINEL" ]; do
        sleep 0.3
    done
    osascript - "$ITERM_NEW_SESSION" <<'APPLESCRIPT' 2>/dev/null
on run argv
    set sid to item 1 of argv
    tell application id "com.googlecode.iterm2"
        repeat with w in windows
            repeat with t in tabs of w
                repeat with s in sessions of t
                    if id of s is sid then
                        tell s to close
                        return
                    end if
                end repeat
            end repeat
        end repeat
    end tell
end run
APPLESCRIPT
    rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
    cat "$OUTPUT_FILE"
    exit 0
fi

if [ "${INSIDE_EMACS:-}" = "vterm" ] && command -v emacsclient >/dev/null 2>&1; then
    SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
    rm -f "$SENTINEL" && mkfifo "$SENTINEL"

    LAUNCH_SCRIPT=$(mktemp "$TMPBASE/revdiff-launch-XXXXXX")
    trap 'rm -f "$OUTPUT_FILE" "$SENTINEL" "$LAUNCH_SCRIPT"' EXIT
    cat > "$LAUNCH_SCRIPT" <<LAUNCHER
#!/bin/sh
cd $(sq "$CWD") && $REVDIFF_CMD; echo d > $(sq "$SENTINEL"); exit
LAUNCHER
    chmod +x "$LAUNCH_SCRIPT"

    EMACS_PID=$(emacsclient --eval '(emacs-pid)' 2>/dev/null | tr -d '"')
    VTERM_PID=$$
    if [ -z "$EMACS_PID" ] || ! [ "$EMACS_PID" -gt 0 ] 2>/dev/null; then
        rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
        echo "error: emacs server not reachable" >&2
        exit 1
    fi
    while P=$(ps -o ppid= -p "$VTERM_PID" 2>/dev/null | tr -d ' '); [ "$P" != "$EMACS_PID" ] && [ "$P" != "1" ] && [ -n "$P" ]; do VTERM_PID=$P; done

    elisp_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
    ESCAPED_TITLE=$(elisp_escape "$OVERLAY_TITLE")
    ESCAPED_SCRIPT=$(elisp_escape "$LAUNCH_SCRIPT")

    emacsclient --eval "(progn (require 'cl-lib)
      (when-let* ((b (cl-find-if (lambda (b) (let ((p (get-buffer-process b))) (and p (= (process-id p) $VTERM_PID)))) (buffer-list)))
                  (w (get-buffer-window b t)))
        (set-frame-parameter (window-frame w) 'revdiff-caller t))
      (let* ((buf (generate-new-buffer \"*revdiff*\"))
             (win (display-buffer buf '((display-buffer-pop-up-frame)
                     (pop-up-frame-parameters . ((name . \"$ESCAPED_TITLE\")))))))
        (set-frame-parameter (window-frame win) 'revdiff-buf (buffer-name buf))))" >/dev/null 2>&1
    emacsclient --no-wait --eval "(progn (require 'cl-lib)
      (when-let* ((f (cl-find-if (lambda (f) (string= (frame-parameter f 'name) \"$ESCAPED_TITLE\")) (frame-list)))
                  (bn (frame-parameter f 'revdiff-buf))
                  (buf (get-buffer bn)))
        (with-current-buffer buf
          (let ((vterm-shell \"$ESCAPED_SCRIPT\"))
            (vterm-mode)))))" >/dev/null 2>&1

    read -r < "$SENTINEL"
    rm -f "$SENTINEL" "$LAUNCH_SCRIPT"
    emacsclient --no-wait --eval "(progn (require 'cl-lib)
      (when-let ((f (cl-find-if (lambda (f) (string= (frame-parameter f 'name) \"$ESCAPED_TITLE\")) (frame-list))))
        (let ((bn (frame-parameter f 'revdiff-buf)))
          (delete-frame f)
          (when-let ((b (and bn (get-buffer bn)))) (kill-buffer b))))
      (when-let ((f (cl-find-if (lambda (f) (frame-parameter f 'revdiff-caller)) (frame-list))))
        (set-frame-parameter f 'revdiff-caller nil)
        (select-frame-set-input-focus f)))" >/dev/null 2>&1
    cat "$OUTPUT_FILE"
    exit 0
fi

echo "error: no overlay terminal available (requires tmux, zellij, kitty, wezterm, cmux, ghostty, iTerm2, or emacs vterm)" >&2
exit 1
