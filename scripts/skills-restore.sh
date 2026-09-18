#!/usr/bin/env bash
# Reinstall every global skill recorded in ~/.agents/.skill-lock.json.
#
# The skills CLI only ships `experimental_install`, which restores a *project*
# skills-lock.json into ./.agents/skills. Global installs have no equivalent, so
# replay the lock through `skills add -g` instead.
set -euo pipefail

LOCK="${SKILL_LOCK:-$HOME/.agents/.skill-lock.json}"
[ -f "$LOCK" ] || { echo "no lock file at $LOCK" >&2; exit 1; }

# Installed from upstream with `disable-model-invocation: true`, which limits them
# to explicit /slash calls. Stripped so the model can reach for them on its own.
MODEL_INVOCABLE=(
  grill-me handoff implement improve-codebase-architecture
  to-issues to-prd to-spec to-tickets writing-great-skills
)

# The agents the lock was built against. `--agent '*'` fans out to every agent the
# CLI knows of — 79 at last count — and litters $HOME with dirs for unused ones.
read -ra AGENTS <<<"$(jq -r '(.lastSelectedAgents // ["claude-code"]) | join(" ")' "$LOCK")"

# GitHub entries install by owner/repo, everything else by its source host.
# `npx` inherits stdin, so feed the loop by redirect rather than a pipe and keep
# stdin off the CLI, or it eats the remaining sources.
while IFS=$'\t' read -r source skills; do
  echo "==> $source"
  # shellcheck disable=SC2086 # $skills is a deliberate argument list
  npx -y skills@latest add -g "$source" --skill $skills --agent "${AGENTS[@]}" -y </dev/null \
    || echo "!! $source failed; install by hand: $skills" >&2
done < <(jq -r '
  .skills | to_entries
  | group_by(if .value.sourceType == "github" then .value.source else "https://" + .value.source end)
  | .[]
  | (if .[0].value.sourceType == "github" then .[0].value.source else "https://" + .[0].value.source end)
    + "\t" + ([.[].key] | join(" "))
' "$LOCK")

# Skills this repo keeps outside the lock, stowed straight into ~/.agents/skills.
# The CLI only links its own installs into the agent dirs, so link these ones here.
mkdir -p "$HOME/.claude/skills"
for dir in "$HOME"/.agents/skills/*/; do
  name="$(basename "$dir")"
  jq -e --arg n "$name" '.skills | has($n)' "$LOCK" >/dev/null && continue
  # Replace our own link, but leave a real directory alone: an agent's own
  # installer may own that path. `ln -shf` spells this differently on GNU, so
  # clear the link by hand instead.
  dest="$HOME/.claude/skills/$name"
  [ -L "$dest" ] && rm -f "$dest"
  [ -e "$dest" ] || ln -s "../../.agents/skills/$name" "$dest"
done

for skill in "${MODEL_INVOCABLE[@]}"; do
  f="$HOME/.agents/skills/$skill/SKILL.md"
  if [ -f "$f" ]; then
    # -i'' is BSD-only; the backup dance is what both seds agree on.
    sed -i.bak '/^disable-model-invocation: true$/d' "$f" && rm -f "$f.bak"
  fi
done
