-- Rex configuration. Apply changes with `rex config reload`.

local home = os.getenv("HOME")

rex.action{
  name = "cairn",
  title = "Toggle Cairn",
  description = "Float the trail of the focused pane's agent session: its chain of PRs and steps, and where it stands.",
  keywords = "pull request github chain progress",
  run = function(ctx)
    if ctx.block_id == nil then error("no focused pane", 0) end
    local res = rex.exec{ home .. "/.local/bin/cairn", "panel", "--lua", ctx.block_id }
    if not res.ok then error(res.stderr ~= "" and res.stderr or "cairn panel failed", 0) end
    loadstring(res.stdout)()
  end,
}

rex.bind("ctrl+cmd+p", "cairn")

-- The server's environment lacks the login PATH that delegate's ssh, jq and
-- rex calls need, hence sourcing ~/.paths.
local prune_script = [==[
source ~/.paths
d=~/.agents/skills/outpost-delegate/scripts/delegate
print 'Scanning outpost…'
out=$("$d" prune 2>&1); rc=$?
print -r -- "$out" | sed $'s/^skip .*/\e[33m&\e[0m/'
if (( rc == 0 )) && [[ ${out##*$'\n'} != '0 to prune'* ]] && read -q '?Apply? [y/N] '; then
  print
  "$d" prune --apply
fi
print
read -sk1 '?Press any key to close'
]==]

rex.action{
  name = "outpost_prune",
  title = "Prune Outpost",
  description = "Float a dry run of `delegate prune` on outpost, and apply it on confirmation.",
  keywords = "delegate worker worktree merged clean",
  run = function()
    local _, err = rex.session.new_layer{
      bounds = { 0.1, 0.1, 0.8, 0.6 },
      focus = true,
      layout = { block = { flavor = "com.superlogical.terminal.shell", label = "outpost-prune",
        options = { command = { "/bin/zsh", "-c", prune_script } } } },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.bind("ctrl+cmd+o", "outpost_prune")
