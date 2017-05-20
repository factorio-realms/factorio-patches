realm.patches.framework = {   -- for framework, has highest priority
  priority = 3
}
realm.patches.scenario = {    -- for scenario script, has lowest priority
  priority = -3
}

--------------------------------------------------------------------------------
-- init and banner

realm.patches.framework.on_init = function()
  global.realm = {
    inited = {},
    task_queue = Queue.new(),
  }
end

realm.patches.framework.on_player_joined_game = function(e)
  local player = game.players[e.player_index]
  player.print({"realm.banner"})
end

realm.patches.framework.on_tick = function(e)
  -- we can not receive on_init in fact
  -- a dangerous way to simulate on_init
  if not global.realm then
    realm.patches.framework.on_init()
  end
  for patch_name, patch in pairs(realm.patches) do
    if not global.realm.inited[patch_name] then
      if patch.on_init then
        patch.on_init()
      end
      global.realm.inited[patch_name] = true
    end
  end
  realm.patches.framework.on_tick = realm.patches.framework.on_tick_real
  return realm.patches.framework.on_tick(e)
end

--------------------------------------------------------------------------------
-- async framework

function realm.next_tick(cb)
  global.realm.next_tick = global.realm.next_tick or {}
  table.insert(global.realm.next_tick, cb)
end

function realm.delay_tasks(tasks, dealer, final)
  local tq = global.realm.task_queue
  for _, data in pairs(tasks) do
    Queue.push(tq, {data=data, dealer=dealer})
    if final then
      Queue.push(tq, {dealer=final})
    end
  end
end

realm.patches.framework.on_tick_real = function(e)
  if global.realm.next_tick then
    for _, impl in pairs(global.realm.next_tick) do
      impl()
    end
    global.realm.next_tick = nil
  end
  local task = Queue.pop(global.realm.task_queue)
  if task then
    task.dealer(task.data)
  end
end

--------------------------------------------------------------------------------
-- event deal

realm_patch_metatable = {
  __index = function(t, k)
    if defines.events[k] then
      return t._event_handlers[defines.events[k]]
    end
    return nil
  end,
  __newindex = function(t, k, v)
    if defines.events[k] then
      t._event_handlers[defines.events[k]] = v
      update_event_mount(defines.events[k])
    else
      rawset(t, k, v)
    end
  end
}

function mount_events()
  -- move all patch.on_xxx to patch._event_handlers[event_id], and set metatable
  for _, patch in pairs(realm.patches) do
    patch._event_handlers = patch._event_handlers or {}
    for k, _ in pairs(patch) do
      if defines.events[k] then
        patch._event_handlers[defines.events[k]] = patch[k]
        patch[k] = nil
      end
    end
    setmetatable(patch, realm_patch_metatable)
  end

  -- sort patches
  realm.patches_sorted = {}
  for patch_name, patch in pairs(realm.patches) do
    patch.name = patch_name
    patch.priority = patch.priority or 0    -- 0 by normal, 3 for framework, -1, -2 for low priority
    table.insert(realm.patches_sorted, patch)
  end
  table.sort(realm.patches_sorted, function(a, b) return a.priority > b.priority end)

  for _, patch in ipairs(realm.patches_sorted) do
    for eid, _ in pairs(patch._event_handlers) do
      update_event_mount(eid)
    end
  end
end

realm.mounted = {}
realm.listeners_cache = {}

function realm_event_handler(e)
  local eid = e.name
  if not realm.listeners_cache[eid] then
    realm.listeners_cache[eid] = {}
    for _, patch in ipairs(realm.patches_sorted) do
      if patch._event_handlers[eid] then
        table.insert(realm.listeners_cache[eid], patch._event_handlers[eid])
      end
    end
  end

  if eid == defines.events.on_tick then
    for _, impl in ipairs(realm.listeners_cache[eid]) do
      impl(e)
    end
  else
    for _, impl in ipairs(realm.listeners_cache[eid]) do
      impl(e)
      local break_deal = false
      for _, x in pairs(e) do
        if type(x) == 'table' and x.valid == false then
          -- something destroyed in previous hook, do not contiue anymore.
          break_deal = true
          break
        end
      end
      if break_deal then break end
    end
  end
end

function update_event_mount(eid)
  if realm.mounted[eid] then
    realm.listeners_cache[eid] = nil
    return
  end

  script_orig.on_event(eid, realm_event_handler)
end

function mount_commands()
  local cmds = {}
  for _, patch in pairs(realm.patches) do
    if patch.commands then
      for cmd_name, cmd_impl in pairs(patch.commands) do
        cmds[cmd_name] = {
          patch = patch,
          impl = cmd_impl
        }
        commands.add_command(cmd_name, 'commands.' .. cmd_name, function(e)
          if e.parameter then
            e.argv = convert_arguments(e.parameter)
          else
            e.argv = {}
          end
          if e.player_index ~= nil then
            e.by_admin = game.players[e.player_index].admin
            e.commander = game.players[e.player_index].name
          else
            e.by_admin = true
            e.commander = "<server>"
          end
          cmds[e.name].impl(e)
        end)
      end
    end
  end
end

function mount_configuration_changed()
  script_orig.on_configuration_changed(function(cc)
    for _, patch in ipairs(realm.patches_sorted) do
      if patch.on_configuration_changed then
        patch.on_configuration_changed(cc)
      end
    end
  end)
end

--------------------------------------------------------------------------------
-- all patches prepared, mount all here
-- after mount, the member of patches cannot modify anymore
-- but still can modify patch in future
-- such as add/remove event listener dynamically (it's a great way to save CPU!!!)

mount_commands()
mount_configuration_changed()
mount_events()

--------------------------------------------------------------------------------
-- after all, we make a fake script variable for scenario script

script = {
  on_init = script_orig.on_init,  -- in fact, we can never receive this
  on_load = script_orig.on_load,
  on_configuration_changed = function(f) realm.patches.scenario.on_configuration_changed = f end,
  on_event = function(eid, f) realm.patches.scenario._event_handlers[eid] = f; update_event_mount(eid) end,
  generate_event_name = script_orig.generate_event_name,
  get_event_handler = function(eid) return realm.patches.scenario._event_handlers[eid] end,
  raise_event = script_orig.raise_event,
}
