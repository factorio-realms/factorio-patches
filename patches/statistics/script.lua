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
  for i = 1,20 do
    if not a[i] then break end
    str = str .. a[i][1] .. '(' .. a[i][2] .. '), '
  end
  str = str:gsub(', $', '')

  game.print({"patch-statistics.stat-by-" .. kind, str})
end

function realm.patches.statistics.commands.stat(e)
  if not e.by_admin then
    print_back(e, {"patch-statistics.not-allowed"})
    return
  end

  local by_surface = {}
  local by_force = {}
  local by_user = {}
  local by_type = {}
  local by_name = {}
  local by_resource = {}

  local chunks = {}
  for _, s in pairs(game.surfaces) do
    for c in s.get_chunks() do
      table.insert(chunks, {surface=s.name, x=c.x, y=c.y})
    end
  end
  realm.delay_tasks(chunks, function(c)
    local s = game.surfaces[c.surface]
    if not s then
      -- surface may deleted during task
      return
    end
    local es = s.find_entities({{c.x * 32, c.y * 32}, {c.x * 32 + 32, c.y * 32 + 32}})
    for _, e in ipairs(es) do
      by_surface[s.name] = (by_surface[s.name] or 0) + 1
      by_force[e.force.name] = (by_force[e.force.name] or 0) + 1
      if e.last_user then
        by_user[e.last_user.name] = (by_user[e.last_user.name] or 0) + 1
      end
      by_type[e.type] = (by_type[e.type] or 0) + 1
      by_name[e.name] = (by_name[e.name] or 0) + 1
      if e.type == 'resource' then
        by_resource[e.name] = (by_resource[e.name] or 0) + e.amount
      end
    end
  end, function()
    game.print({"patch-statistics.banner"})
    statistics_show_statistics('surface', by_surface)
    statistics_show_statistics('force', by_force)
    statistics_show_statistics('user', by_user)
    statistics_show_statistics('name', by_name)
    statistics_show_statistics('type', by_type)
    statistics_show_statistics('resource', by_resource)
  end)

  local need_time = math.ceil(#chunks / 60 / 60 / game.speed * 10) / 10
  game.print({"patch-statistics.task-posted", need_time})
end
