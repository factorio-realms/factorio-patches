realm.patches.announcement = {
  commands = {}
}

function announcement_update_gui()
  for _, p in pairs(game.players) do
    local root = mod_gui and mod_gui.get_frame_flow(p) or p.gui.left
    if not root.announcement then
      local announcement = root.add{type='frame', name='announcement'}
      announcement.style.minimal_width = 230
      announcement.style.top_padding = 4
      announcement.style.bottom_padding = 4
      local layout = announcement.add{type='table', name='layout', colspan=1}
      local title = layout.add{type='label', name='title', caption={'patch-announcement.title'}}
      title.style = 'caption_label_style'
    end
    if not global.announcement or global.announcement == "" then
      root.announcement.style.visible = false
    else
      root.announcement.style.visible = true
      if root.announcement.layout.body then
        root.announcement.layout.body.destroy()
      end
      local body = root.announcement.layout.add{type='table', name='body', colspan=1}
      for str in global.announcement:lines() do
        str = str:gsub('@NAME@', p.name)
        body.add{type='label', caption=str}
      end
    end
  end
end

function announcement_show_editor(player)
  if not multiline_editor_show then
    print_to(player, {"patch-announcement.multiline-editor-required"})
  end
  multiline_editor_show(player, {text=global.announcement, caption={"patch-announcement.title"}}, function(e)
    global.announcement = e.text
    announcement_update_gui()
    if global.announcement and global.announcement ~= "" then
      game.print({"patch-announcement.updated", player.name})
    end
  end)
end

function announcement_find_ancestor(e, name)
  while e do
    if e.name == name then
      return e
    end
    e = e.parent
  end
  return nil
end

function realm.patches.announcement.on_gui_click(e)
  local player = game.players[e.player_index]
  if announcement_find_ancestor(e.element, 'announcement') then
    local body = announcement_find_ancestor(e.element, 'body')
    local ann = announcement_find_ancestor(e.element, 'announcement')
    if body and player.admin then
      announcement_show_editor(player)
    else
      if ann.layout.body.style.visible == nil then
        ann.layout.body.style.visible = true
      end
      ann.layout.body.style.visible = not ann.layout.body.style.visible
    end
  end
end

function realm.patches.announcement.commands.announcement(e)
  if not e.by_admin then
    print_back(e, {"patch-announcement.not-allowed"})
    return
  end
  if e.argv[1] == "set" then
    global.announcement = e.argv[2]
    announcement_update_gui()
    if global.announcement ~= "" then
      game.print(e, {"patch-announcement.updated", e.commander})
    end
  elseif e.argv[1] == "clear" then
    global.announcement = nil
    announcement_update_gui()
  elseif e.argv[1] == "edit" then
    if not e.player_index then
      print("This command cannot invoked via terminal")
      return
    end
    local player = game.players[e.player_index]
    announcement_show_editor(player)
  else
    print_back(e, {"patch-announcement.bad-command"})
  end
end
