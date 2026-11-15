-- rex do -s <task> wait.lua timeout=<seconds> states=<a,b>
-- Prints the worker's status as JSON once it reports one of `states`, or exits
-- 124 at the timeout.
local terminal = "com.superlogical.terminal"
local wanted = {}
for s in rex.args.states:gmatch("[^,]+") do
  wanted[s] = true
end
local deadline = os.time() + tonumber(rex.args.timeout)

-- Rex holds no status record once the agent has exited, since its terminal
-- closes with it or holds a bare shell once Rex restores the session, nor for a
-- new agent until it first reports.
local function record()
  local block = assert(rex.call("session.list_blocks", { session_id = rex.session_id })).blocks[1]
  return block and assert(rex.block.call(terminal, "program_status", { block_id = block.block_id })).records[1]
end

local function settled(r)
  local state = r and r.state or "exited"
  if wanted[state] then
    print(string.format('{"status":"%s"%s}', state,
      r and r.kind and string.format(',"kind":"%s"', r.kind) or ""))
    rex.stop(0)
  end
end

-- Re-read the status between short waits, so a change that lands before the
-- wait starts is still seen. An exit raises another event than the one waited
-- on, so it shows up at the next re-read.
while os.time() < deadline do
  settled(record())
  local ev = rex.wait("terminal.program_status_changed", function(e)
    return e.record and wanted[e.record.state]
  end, math.min(30, deadline - os.time()))
  if ev then settled(ev.record) end
end
rex.stop(124)
