-- Rex configuration. Apply changes with `rex config reload`.

local home = os.getenv("HOME")

rex.action{
  name = "cairn",
  title = "Toggle Cairn",
  description = "Float the trail of the focused pane's agent session: its chain of PRs and steps, and where it stands.",
  keywords = "pull request github chain progress",
  run = function(ctx)
    if ctx.block_id == nil then error("no focused pane", 0) end
    local res = rex.exec{ home .. "/.local/bin/cairn", "panel", ctx.block_id }
    if not res.ok then error(res.stderr ~= "" and res.stderr or "cairn panel failed", 0) end
  end,
}

rex.bind("ctrl+cmd+p", "cairn")
