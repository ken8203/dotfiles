-- Rex configuration. Apply changes with `rex config reload`.

local home = os.getenv("HOME")
local panel_label = "trail"

local function window_of(view, block_id)
  for _, window in ipairs(view.windows) do
    for _, layer in ipairs(window.layers) do
      for _, block in ipairs(layer.blocks) do
        if block.block_id == block_id then return window end
      end
    end
  end
end

rex.action{
  name = "trail",
  title = "Toggle Trail",
  description = "Float the focused pane's trail: its chain of PRs and steps, and where it stands.",
  keywords = "pull request github chain progress",
  run = function(ctx)
    if ctx.block_id == nil then error("no focused pane", 0) end
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local window = window_of(view, ctx.block_id)
    if window == nil then error("focused pane not found", 0) end

    for _, layer in ipairs(window.layers) do
      if layer.kind ~= "tiled" then
        for _, block in ipairs(layer.blocks) do
          if block.label == panel_label then
            local _, close_err = rex.session.close_layer{ layer_id = layer.layer_id }
            if close_err ~= nil then error(close_err, 0) end
            return
          end
        end
      end
    end

    local _, open_err = rex.session.new_layer{
      window_id = window.window_id,
      bounds = { 0.1, 0.1, 0.8, 0.5 },
      focus = true,
      layout = { block = {
        flavor = "com.superlogical.terminal.shell",
        label = panel_label,
        options = { command = { home .. "/.local/bin/trail", "watch", ctx.block_id } },
      } },
    }
    if open_err ~= nil then error(open_err, 0) end
  end,
}

rex.bind("ctrl+cmd+p", "trail")
