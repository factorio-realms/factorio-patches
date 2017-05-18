realm.framework = {}

realm.framework.on_player_joined_game = function(e)
  local player = game.players[e.player_index]
  player.print({"realm.banner"})
end

realm.framework.on_init = function()
  global.realm = {
    inited = {}
  }
end

realm.framework.on_tick = function(e)
  -- we can not receive on_init in fact
  -- a dangerous way to simulate on_init
  if not global.realm then
    realm.framework.on_init()
  end
  for patch_name, patch in pairs(realm.patches) do
    if not global.realm.inited[patch_name] then
      if patch.on_init then
        patch.on_init()
      end
      global.realm.inited[patch_name] = true
    end
  end
  realm.framework.on_tick = realm.framework.on_tick_real
  return realm.framework.on_tick(e)
end

realm.framework.on_tick_real = function(e)
  if global.realm.next_tick then
    for _, impl in pairs(global.realm.next_tick) do
      impl()
    end
    global.realm.next_tick = nil
  end
end

function realm.next_tick(cb)
  global.realm.next_tick = global.realm.next_tick or {}
  table.insert(global.realm.next_tick, cb)
end

EVENT_NAME_BY_ID = {}
for name, id in pairs(defines.events) do
  EVENT_NAME_BY_ID[id] = name
end

realm.mounted = {}
realm.listeners_cache = {}

function remount_event(event_id)
  if realm.mounted[event_id] then
    realm.listeners_cache[event_id] = nil
    return
  end
  
  script_orig.on_event(event_id, function(e)
    if not realm.listeners_cache[event_id] then
      local cache = {}
      local event_name = EVENT_NAME_BY_ID[event_id]
      if event_name and realm.framework[event_name] then
        table.insert(cache, realm.framework[event_name])
      end
      for _, patch in pairs(realm.patches) do
        if event_name and patch[event_name] then
          table.insert(cache, patch[event_name])
        end
        if patch.on_event and patch.on_event[event_id] then
          table.insert(cache, patch.on_event[event_id])
        end
      end
      realm.listeners_cache[event_id] = cache
    end
    for _, impl in ipairs(realm.listeners_cache[event_id]) do
      impl(e)
    end
  end)
end

function mount_events()
  local listeners = {realm.framework}
  for _, patch in pairs(realm.patches) do
    table.insert(listeners, patch)
  end

  for _, l in ipairs(listeners) do
    for k, _ in pairs(l) do
      if defines.events[k] then
        remount_event(defines.events[k])
      end
    end
    if l.on_event then
      for id, _ in pairs(l.on_event) do
        remount_event(id)
      end
    end
  end
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
    if realm.framework.on_configuration_changed then
      realm.framework.on_configuration_changed(cc)
    end
    for _, patch in pairs(realm.patches) do
      if patch.on_configuration_changed then
        patch.on_configuration_changed(cc)
      end
    end
  end)
end

mount_commands()
mount_events()    -- events maybe remount during scenario's script or dynamic on_event
mount_configuration_changed()

