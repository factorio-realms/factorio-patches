realm.patches.target = {
  commands = {}
}

function target_update_gui()
  for _, p in pairs(game.players) do
    local root = mod_gui and mod_gui.get_frame_flow(p) or p.gui.left
    if not root.target then
      local target = root.add{type='frame', name='target'}
      target.style.minimal_width = 230
      target.style.maximal_width = 230
      target.style.top_padding = 4
      target.style.bottom_padding = 4
      local layout = target.add{type='table', name='layout', colspan=1}
      local title = layout.add{type='label', name='title', caption={'patch-target.title'}}
      title.style = 'caption_label_style'
    end
    local force_targets = global.targets and global.targets[p.force.name]
    if not force_targets or next(force_targets) == nil then
      root.target.style.visible = false
    else
      root.target.style.visible = true
      if root.target.layout.body then
        root.target.layout.body.destroy()
      end
      local body = root.target.layout.add{type='table', name='body', colspan=1}
      body.style.bottom_padding = 5
      for _, target in pairs(force_targets) do
        local item = body.add{type='flow', direction='horizontal'}
        local icon = item.add{type='sprite-button', name='icon', sprite=target_get_icon(target)}
        icon.style = 'slot_button_style'
        local right = item.add{type='flow', name='line1', direction='vertical'}
        local x = {"patch-target." .. target.type .. "-completed", target.cur, target.total}
        right.add{type='label', name='status', caption=x}
        local bar = right.add{type='progressbar', size=168, value=target.cur/target.total}
        bar.style.minimal_width = 168
        bar.style.maximal_width = 168
        bar.style.right_padding = 0
      end
    end
  end
end

function target_get_technology_level(force, tech)
  local x = force.technologies[tech] or force.technologies[tech .. '-1']
  while x.researched do
    if force.technologies[tech .. '-' .. (x.level + 1)] then
      x = force.technologies[tech .. '-' .. (x.level + 1)]
    else
      break
    end
  end
  if x.researched then
    if x.level > 0 then
      return x.level
    else
      return 1
    end
  else
    if x.level > 0 then
      return x.level -1
    else
      return 0
    end
  end
end

function target_get_icon(target)
  if target.type == "item" then
    return "item/" .. target.name
  elseif target.type == "fluid" then
    return "fluid/" .. target.name
  elseif target.type == "technology" then
    local techs = game.technology_prototypes
    local x = techs[target.name] or techs[target.name .. '-1']
    return "technology/" .. x.name
  elseif target.type == "launched" then
    return "item/" .. target.name
  end
end

function target_update_one(force, target)
  if target.cur >= target.total then
    -- already complete, do nothing
    return
  end
  if target.type == "item" then
    local flow = force.item_production_statistics
    target.cur = flow.get_input_count(target.name) or 0
  elseif target.type == "fluid" then
    local flow = force.fluid_production_statistics
    target.cur = flow.get_input_count(target.name) or 0
    target.cur = math.floor(target.cur * 10) / 10
  elseif target.type == "technology" then
    target.cur = target_get_technology_level(force, target.name)
  elseif target.type == "launched" then
    target.cur = force.get_item_launched(target.name)
  end
  if target.cur > target.total then
    target.cur = target.total
  end
end

function target_is_all_completed(force_targets)
  if not next(force_targets) then
    return false
  end
  for _, t in pairs(force_targets) do
    if t.cur < t.total then
      return false
    end
  end
  return true
end

function target_update_stat()
  if not global.targets then
    return
  end
  for force_name, force_targets in pairs(global.targets) do
    local force = game.forces[force_name]
    for _, t in ipairs(force_targets) do
      target_update_one(force, t)
    end
    if not global.target_completed then
      if target_is_all_completed(force_targets) then
        global.target_completed = true
        game.set_game_state{game_finished=true, player_won=true, can_continue=true}
      end
    end
  end
end

function realm.patches.target.on_tick(e)
  -- update per 5 secs
  if game.tick % 331 == 137 then
    target_update_stat()
    target_update_gui()
  end
end

function target_has_target()
  if not global.targets then
    return false
  end
  for _, ft in pairs(global.targets) do
    if next(ft) then
      return true
    end
  end
  return false
end

function realm.patches.target.commands.target(e)
  if not e.by_admin then
    print_back(e, {"patch-target.not-allowed"})
    return
  end
  if not e.player_index then
    print_back(e, {"patch-target.cannot-run-in-terminal"})
    return
  end

  local player = game.players[e.player_index]
  local force = player.force

  if e.argv[1] == 'add' then
    -- /target add <type> <name> <number>
    local type = e.argv[2]
    local name = e.argv[3]
    local number = tonumber(e.argv[4])

    if type == 'item' then
      if not game.item_prototypes[name] then
        print_back(e, {"patch-target.item-not-exists", name})
        return
      end
    elseif type == 'fluid' then
      if not game.fluid_prototypes[name] then
        print_back(e, {"patch-target.fluid-not-exists", name})
        return
      end
    elseif type == 'technology' then
      local techs = game.technology_prototypes
      if not techs[name] and not techs[name .. '-1'] then
        print_back(e, {"patch-target.technology-not-exists", name})
        return
      end
    elseif type == 'launched' then
      if not game.item_prototypes[name] then
        print_back(e, {"patch-target.item-not-exists", name})
        return
      end
    else
      print_back(e, {"patch-target.bad-command"})
      return
    end

    if not number then
      print_back(e, {"patch-target.bad-command"})
      return
    end
    number = math.ceil(number)

    global.targets = global.targets or {}
    global.targets[force.name] = global.targets[force.name] or {}
    table.insert(global.targets[force.name], {
      type = type,
      name = name,
      cur = -1,
      total = number,
    })

    target_update_stat()
    target_update_gui()
  elseif e.argv[1] == 'remove' then
    -- /target remove <index>
    local index = tonumber(e.argv[2])
    if not index or index % 1 ~= 0 then
      print_back(e, {"patch-target.bad-command"})
      return
    end
    if not global.targets or not global.targets[force.name] then
      print_back(e, {"patch-target.out-of-range"})
      return
    end
    if index < 1 or index > #global.targets[force.name] then
      print_back(e, {"patch-target.out-of-range"})
      return
    end
    table.remove(global.targets[force.name], index)

    target_update_gui()
  else
    print_back(e, {"patch-target.bad-command"})
    return
  end

  if target_has_target() then
    -- disable default task
    remote.call('silo_script', 'set_finish_on_launch', false)
    game.print{"patch-target.default-task-disabled"}
  else
    remote.call('silo_script', 'set_finish_on_launch', true)
    game.print{"patch-target.default-task-enabled"}
  end
end

realm.patches.target.commands['help-target'] = function(e)
  print_back(e, {'patch-target.help-1'})
  print_back(e, {'patch-target.help-2'})
  print_back(e, {'patch-target.help-3'})
  print_back(e, {'patch-target.help-4'})
  print_back(e, {'patch-target.help-11'})
  print_back(e, {'patch-target.help-12'})
  print_back(e, {'patch-target.help-13'})
end
