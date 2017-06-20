realm.patches.statistics = {
  commands = {}
}

function statistics_show_statistics(kind, stat)
  local a = {}
  for name, count in pairs(stat) do
    table.insert(a, {name, count})
  end
  table.sort(a, function(a, b) return a[2] > b[2] end)

  local str = ""
  for i = 1,50 do
    if not a[i] then break end
    str = str .. a[i][1] .. '(' .. a[i][2] .. '), '
  end
  str = str:gsub(', $', '')

  game.print({"patch-statistics.stat-by-" .. kind, str})
  game.write_file("stat.txt", 
      "by-" .. kind .. ": " .. str .. "\n",
      true)
end

function statistics_update_progress(cur, total)
  for _, p in pairs(game.players) do
    local root = mod_gui and mod_gui.get_frame_flow(p) or p.gui.left
    if not root.statistics then
      local statistics = root.add{type='frame', name='statistics'}
      statistics.style.minimal_width = 230
      statistics.style.top_padding = 4
      statistics.style.bottom_padding = 4
      local layout = statistics.add{type='table', name='layout', colspan=1}
      local title = layout.add{type='label', name='title', caption={'patch-statistics.title'}}
      title.style = 'caption_label_style'
    end
    if total == 0 then
      root.statistics.style.visible = false
    else
      root.statistics.style.visible = true
      if root.statistics.layout.body then
        root.statistics.layout.body.destroy()
      end
      local body = root.statistics.layout.add{type='table', name='body', colspan=1}
      body.style.bottom_padding = 4
      body.add{type='progressbar', size=168, value=cur/total}
    end
  end
end

function statistics_update(c, i, ctx)
  local s = game.surfaces[c.surface]
  if not s then
    -- surface may deleted during task
    return
  end
  local es = s.find_entities({{c.x * 32, c.y * 32}, {c.x * 32 + 32, c.y * 32 + 32}})
  for _, e in ipairs(es) do
    ctx.by_surface[s.name] = (ctx.by_surface[s.name] or 0) + 1
    ctx.by_force[e.force.name] = (ctx.by_force[e.force.name] or 0) + 1
    if e.last_user then
      ctx.by_user[e.last_user.name] = (ctx.by_user[e.last_user.name] or 0) + 1
    end
    ctx.by_type[e.type] = (ctx.by_type[e.type] or 0) + 1
    ctx.by_name[e.name] = (ctx.by_name[e.name] or 0) + 1
    if e.type == 'resource' then
      ctx.by_resource[e.name] = (ctx.by_resource[e.name] or 0) + e.amount
    end
  end
  if i % 60 == 0 then
    statistics_update_progress(i, #ctx.chunks)
  end
end

function statistics_final(data, _, ctx)
    statistics_update_progress(0, 0)

    game.print({"patch-statistics.banner"})
    game.write_file("stat.txt", 
        "Game stat(" .. game.tick .. "):\n",
        true)
    statistics_show_statistics('surface', ctx.by_surface)
    statistics_show_statistics('force', ctx.by_force)
    statistics_show_statistics('user', ctx.by_user)
    statistics_show_statistics('name', ctx.by_name)
    statistics_show_statistics('type', ctx.by_type)
    statistics_show_statistics('resource', ctx.by_resource)
    game.write_file("stat.txt", "\n\n", true)
    game.print({"patch-statistics.written-to-file"})
end

function realm.patches.statistics.commands.stat(e)
  if not e.by_admin then
    print_back(e, {"patch-statistics.not-allowed"})
    return
  end

  local stat = {
    by_surface = {},
    by_force = {},
    by_user = {},
    by_type = {},
    by_name = {},
    by_resource = {},
  }

  local chunks = {}
  for _, s in pairs(game.surfaces) do
    for c in s.get_chunks() do
      table.insert(chunks, {surface=s.name, x=c.x, y=c.y})
    end
  end
  statistics_update_progress(0, #chunks)
  stat.chunks = chunks

  realm.delay_tasks(chunks, statistics_update, statistics_final, stat)

  local need_time = math.ceil(#chunks / 60 / 60 / game.speed * 10) / 10
  game.print({"patch-statistics.task-posted", need_time})
end
