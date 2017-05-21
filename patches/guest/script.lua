realm.patches.guest = {
  commands = {}
}

function guest_get_guest_permission_group()
  for _, group in pairs(game.permissions.groups) do
    if group.name == "guest" then
      return group
    end
  end
  local group = game.permissions.create_group("guest")
  -- following strange code just for debuging perms (for find out why sth. cannot do)
  -- and there codes will not use too much cpu, so just keep it
  local perms = {}
  for perm, _ in pairs(defines.input_action) do
    table.insert(perms, perm)
  end
  table.sort(perms)
  -- print("total perms: " .. #perms)
  for i = 1, math.min(#perms, 2000) do
    group.set_allows_action(defines.input_action[perms[i]], false)
    -- print("guest disable: " .. perms[i])
  end

  group.set_allows_action(defines.input_action.start_walking, true)
  group.set_allows_action(defines.input_action.stop_walking, true)
  group.set_allows_action(defines.input_action.stop_mining, true)
  group.set_allows_action(defines.input_action.stop_repair, true)
  group.set_allows_action(defines.input_action.stop_movement_in_the_next_tick, true)
  group.set_allows_action(defines.input_action.open_gui, true)
  group.set_allows_action(defines.input_action.close_gui, true)
  group.set_allows_action(defines.input_action.open_character_gui, true)
  group.set_allows_action(defines.input_action.open_technology_gui, true)
  group.set_allows_action(defines.input_action.gui_click, true)
  group.set_allows_action(defines.input_action.gui_text_changed, true)
  group.set_allows_action(defines.input_action.gui_checked_state_changed, true)
  group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
  group.set_allows_action(defines.input_action.open_blueprint_library_gui, true)
  group.set_allows_action(defines.input_action.open_production_gui, true)
  group.set_allows_action(defines.input_action.open_kills_gui, true)
  group.set_allows_action(defines.input_action.open_train_gui, true)
  group.set_allows_action(defines.input_action.open_train_station_gui, true)
  group.set_allows_action(defines.input_action.open_bonus_gui, true)
  group.set_allows_action(defines.input_action.open_trains_gui, true)
  group.set_allows_action(defines.input_action.open_achievements_gui, true)
  group.set_allows_action(defines.input_action.open_tutorials_gui, true)
  group.set_allows_action(defines.input_action.open_logistic_gui, true)
  group.set_allows_action(defines.input_action.gui_elem_selected, true)
  group.set_allows_action(defines.input_action.change_active_item_group_for_crafting, true)
  group.set_allows_action(defines.input_action.change_active_item_group_for_filters, true)
  group.set_allows_action(defines.input_action.clean_cursor_stack, true)
  group.set_allows_action(defines.input_action.cancel_craft, true)
  group.set_allows_action(defines.input_action.multiplayer_init, true)
  group.set_allows_action(defines.input_action.custom_input, true)
  group.set_allows_action(defines.input_action.player_join_game, true)
  group.set_allows_action(defines.input_action.player_leave_game, true)
  group.set_allows_action(defines.input_action.set_allow_commands, true)
  group.set_allows_action(defines.input_action.server_command, true)
  group.set_allows_action(defines.input_action.write_to_console, true)
  -- following perms should be enabled, otherwise guest admin cannot unguest himself
  group.set_allows_action(defines.input_action.add_permission_group, true)
  group.set_allows_action(defines.input_action.delete_permission_group, true)
  group.set_allows_action(defines.input_action.edit_permission_group, true)
  -- drinving
  group.set_allows_action(defines.input_action.toggle_driving, true)
  return group
end

function guest_set_as_guest(player, b)
  local group = guest_get_guest_permission_group()

  if b then
    group.add_player(player)
    player.tag = "[guest]"
  else
    group.remove_player(player)
    player.tag = ""
  end
end

function guest_get_guests()
  local group = guest_get_guest_permission_group()

  return group.players
end

realm.patches.guest.commands.guest = function(e)
  if not e.by_admin then
    print_back(e, {"cant-run-command-not-admin", e.name})
    return
  end

  if not e.argv[1] then
    print_back(e, {"patch-guest.bad-command", "guest"})
    return
  end

  local player = game.players[e.argv[1]]
  if not player then
    print_back(e, {"patch-guest.player-not-exists", e.argv[1]})
    return
  end

  guest_set_as_guest(player, true)
  player.print{"patch-guest.you-have-been-set-as-guest"}

  game.print{"patch-guest.set-as-guest", player.name, e.commander}
end

realm.patches.guest.commands.unguest = function(e)
  if not e.by_admin then
    print_back(e, {"cant-run-command-not-admin", e.name})
    return
  end

  if not e.argv[1] then
    print_back(e, {"patch-guest.bad-command", "unguest"})
    return
  end

  local player = game.players[e.argv[1]]
  if not player then
    print_back(e, {"patch-guest.player-not-exists", e.argv[1]})
    return
  end

  guest_set_as_guest(player, false)

  game.print{"patch-guest.remove-from-guest", player.name, e.commander}
end

realm.patches.guest.commands.guests = function(e)
  local players = guest_get_guests()
  print_back(e, {"patch-guest.guests-banner", #players})
  for _, p in ipairs(players) do
    if p.connected then
      print_back(e, {"patch-guest.guest-online", p.name})
    else
      print_back(e, {"patch-guest.guest-offline", p.name})
    end
  end
end

realm.patches.guest.commands["new-player-as-guest"] = function(e)
  if e.argv[1] == "on" then
    global.new_player_as_guest = true
  elseif e.argv[1] == "off" then
    global.new_player_as_guest = false
  elseif e.argv[1] == nil then
    -- do nothing here
  else
    print_back(e, {"patch-guest.bad-command", e.name})
    return
  end
  if global.new_player_as_guest then
    print_back(e, {"patch-guest.new-player-as-guest-on"})
  else
    print_back(e, {"patch-guest.new-player-as-guest-off"})
  end
end

realm.patches.guest.on_player_created = function(e)
  if global.new_player_as_guest then
    local player = game.players[e.player_index]
    guest_set_as_guest(player, true)
    player.print{"patch-guest.you-have-been-set-as-guest"}
  end
end
