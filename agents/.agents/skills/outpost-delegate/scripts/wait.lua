-- rex do -s <task> wait.lua timeout=<seconds> states=<a,b>
-- Prints the worker's status as JSON once it reports one of `states`, or exits
-- 124 at the timeout.
local terminal = "com.superlogical.terminal"
local wanted = {}
for s in rex.args.states:gmatch("[^,]+") do
  wanted[s] = true
end
local deadline = os.time() + tonumber(rex.args.timeout)

local blocks = assert(rex.call("session.list_blocks", { session_id = rex.session_id }))
local block = blocks.blocks[1].block_id

local function settled(record)
  if record and wanted[record.state] then
    print(string.format('{"status":"%s"%s}', record.state,
      record.kind and string.format(',"kind":"%s"', record.kind) or ""))
    rex.stop(0)
  end
end

-- Re-read the status between short waits, so a change that lands before the
-- wait starts is still seen.
while os.time() < deadline do
  settled(assert(rex.block.call(terminal, "program_status", { block_id = block })).records[1])
  local ev = rex.wait("terminal.program_status_changed", function(e)
    return e.record and wanted[e.record.state]
  end, math.min(30, deadline - os.time()))
  if ev then settled(ev.record) end
end
rex.stop(124)
