realm.framework = {}

realm.framework.on_player_joined_game = function(e)
  local player = game.players[e.player_index]
  player.print({"realm.banner"})
end

function mount_event(event, name)
  local listeners = {}

  -- framework listener always be first
  if realm.framework[name] then
    table.insert(listeners, realm.framework[name])
  end

  for _, patch in pairs(realm.patches) do
    if patch[name] then
      table.insert(listeners, patch[name])
    end
  end

  if #listeners == 0 then
    return
  end

  local orig_listener = script.get_event_handler(event)
  if orig_listener then
    table.insert(listeners, orig_listener)
  end

  script.on_event(event, function(e)
    for _, l in ipairs(listeners) do
      l(e)
    end
  end)
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
            e.by_console = false
          else
            e.by_admin = true
            e.by_console = true
          end
          cmds[e.name].impl(e)
        end)
      end
    end
  end
end

function mount_events()
  mount_event(defines.events.on_player_joined_game, "on_player_joined_game")
end


mount_commands()
mount_events()

