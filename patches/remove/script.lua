realm.patches.remove = {
  commands = {}
}

function realm.patches.remove.on_init()
  global.remove_task_queue = Queue.new()
  global.auto_remove_task = {}
end

function realm.patches.remove.on_chunk_generated(e)
  local x = e.area.left_top.x / 32
  local y = e.area.left_top.y / 32
  if global.auto_remove_task.trees then
    remove_remove_trees(e.surface, x, y)
  end
  if global.auto_remove_task.enemies then
    remove_remove_enemies(e.surface, x, y)
  end
  if global.auto_remove_task.decorations then
    remove_remove_decorations(e.surface, x, y)
  end
end

function remove_refresh_map(surface, x, y)
  for _, force in pairs(game.forces) do
    if force.is_chunk_charted(surface, {x, y}) then
      force.chart(surface, {{x * 32 + 10, y * 32 + 10}, {x * 32 + 11, y * 32 + 11}})
    end
  end
end

function remove_remove_trees(surface, x, y)
  local area = {{x * 32, y * 32}, {x * 32 + 32, y * 32 + 32}}
  for _, e in pairs(surface.find_entities_filtered{area=area, type='tree'}) do
    e.destroy()
  end
  remove_refresh_map(surface, x, y)
end

function remove_remove_enemies(surface, x, y)
  local area = {{x * 32, y * 32}, {x * 32 + 32, y * 32 + 32}}
  for _, e in pairs(surface.find_entities_filtered{area=area, force=game.forces.enemy}) do
    e.destroy()
  end
  remove_refresh_map(surface, x, y)
end

function remove_remove_decorations(surface, x, y)
  local area = {{x * 32, y * 32}, {x * 32 + 32, y * 32 + 32}}
  surface.destroy_decoratives(area)
end

function realm.patches.remove.on_tick()
  local task = Queue.pop(global.remove_task_queue)
  if task then
    if task.kind == 'trees' then
      remove_remove_trees(game.surfaces[task.surface], task.x, task.y)
    elseif task.kind == 'enemies' then
      remove_remove_enemies(game.surfaces[task.surface], task.x, task.y)
    elseif task.kind == 'decorations' then
      remove_remove_decorations(game.surfaces[task.surface], task.x, task.y)
    end
  end
end

function remove_push_all_chunks_to_queue(task_name)
  for _, surface in pairs(game.surfaces) do
    for chunk in surface.get_chunks() do
      Queue.push(global.remove_task_queue, {
        kind = task_name,
        surface = surface.name,
        x = chunk.x,
        y = chunk.y,
      })
    end
  end
end

function realm.patches.remove.commands.remove(e)
  if not e.by_admin then
    print_back(e, {"patch-remove.not-allowed"})
    return
  end
  if e.argv[1] == 'trees' then
    remove_push_all_chunks_to_queue('trees')
    print_back(e, {"patch-remove.task-posted"})
  elseif e.argv[1] == 'enemies' then
    -- clear twice to prevent vestigital
    remove_push_all_chunks_to_queue('enemies')
    remove_push_all_chunks_to_queue('enemies')
    print_back(e, {"patch-remove.task-posted"})
  elseif e.argv[1] == 'decorations' then
    remove_push_all_chunks_to_queue('decorations')
    print_back(e, {"patch-remove.task-posted"})
  else
    print_back(e, {"patch-remove.bad-command", e.name})
    return
  end
end

realm.patches.remove.commands["auto-remove"] = function(e)
  if not e.by_admin then
    print_back(e, {"patch-remove.not-allowed"})
    return
  end
  local kind = e.argv[1]
  local status = e.argv[2]
  if kind ~= 'trees' and kind ~= 'enemies' and kind ~= 'decorations' then
    print_back(e, {"patch-remove.bad-command", e.name})
    return
  end
  local turn
  if status == nil or status == "on" then
    status = "on"
    turn = true
  elseif status == "off" then
    turn = false
  else
    print_back(e, {"patch-remove.bad-command", e.name})
    return
  end
  global.auto_remove_task[kind] = turn
  game.print({"patch-remove.auto-remove-" .. kind .. "-" .. status})
end
