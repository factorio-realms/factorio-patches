realm.patches.launched_panel = {
  commands = {},
  priority = -4,  -- run after scenario script, to hide silo panel immediately
}

function launched_panel_format_count(n)
  if n < 1000 then
    return n .. ''
  elseif n < 100 * 1000 then
    return (math.floor(n / 100) / 10) .. 'k'
  elseif n < 1000 * 1000 then
    return math.floor(n / 1000) .. 'k'
  elseif n < 100 * 1000000 then
    return (math.floor(n / 100000) / 10) .. 'm'
  elseif n < 1000 * 1000000 then
    return math.floor(n / 1000000) .. 'm'
  elseif n < 100 * 1000000000 then
    return (math.floor(n / 100000000) / 10) .. 'g'
  elseif n < 1000 * 1000000000 then
    return math.floor(n / 1000000000) .. 'g'
  else
    return '...'
  end
end

function launched_panel_update_gui()
  for _, p in pairs(game.players) do
    local root = mod_gui and mod_gui.get_frame_flow(p) or p.gui.left
    if not root.launched_panel then
      local launched_panel = root.add{type='frame', name='launched_panel'}
      launched_panel.style.minimal_width = 230
      launched_panel.style.maximal_width = 230
      launched_panel.style.top_padding = 4
      launched_panel.style.bottom_padding = 4
      local layout = launched_panel.add{type='table', name='layout', colspan=1}
      local title = layout.add{type='label', name='title', caption={'gui-silo-script.frame-caption'}}
      title.style = 'caption_label_style'
    end
    local items_launched = p.force.items_launched
    if not items_launched or next(items_launched) == nil then
      root.launched_panel.style.visible = false
    else
      root.launched_panel.style.visible = true
      if root.launched_panel.layout.body then
        root.launched_panel.layout.body.destroy()
      end
      local body = root.launched_panel.layout.add{type='table', name='body', colspan=5}
      body.style.bottom_padding = 4
      for item_name, n in pairs(items_launched) do
        local x = body.add{type='sprite-button', sprite='item/'..item_name, style='slot_button_style'}
        -- hack for align right
        local ttt = x.add{type='table', colspan=1}
        ttt.style.column_alignments[1] = 'right'
        local placeholder = ttt.add{type='label'}
        placeholder.style.minimal_width = 30
        placeholder.style.minimal_height = 12
        local l = ttt.add{type='label', caption=launched_panel_format_count(n)}
        l.style.font = 'default-small'
      end
    end
    -- hide original panel
    if mod_gui.get_frame_flow(p).silo_gui_frame then
      mod_gui.get_frame_flow(p).silo_gui_frame.style.visible = false
    end
    if mod_gui.get_button_flow(p).silo_gui_sprite_button then
      mod_gui.get_button_flow(p).silo_gui_sprite_button.style.visible = false
    end
  end
end

function launched_panel_find_ancestor(e, name)
  while e do
    if e.name == name then
      return e
    end
    e = e.parent
  end
  return nil
end

function realm.patches.launched_panel.on_gui_click(e)
  local player = game.players[e.player_index]
  if launched_panel_find_ancestor(e.element, 'launched_panel') then
    local ann = launched_panel_find_ancestor(e.element, 'launched_panel')
    if ann.layout.body.style.visible == nil then
      ann.layout.body.style.visible = true
    end
    ann.layout.body.style.visible = not ann.layout.body.style.visible
  end
end

function realm.patches.launched_panel.on_rocket_launched(e)
  launched_panel_update_gui()
end
