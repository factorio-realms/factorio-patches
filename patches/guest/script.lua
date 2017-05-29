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
  -- toggle show entity info
  group.set_allows_action(defines.input_action.toggle_show_entity_info, true)
  return group
end

function guest_ensure_init()
  if not global.guest_info then
    global.guest_info = {}
    for _, p in pairs(game.players) do
      local x = {}
      x.name = p.name
      -- be compatible with old version
      if p.permission_group and p.permission_group.name == 'guest' then
        x.type = 'guest'
      else
        x.type = 'member'
      end
      global.guest_info[p.name] = x
    end
  end
end

function guest_notice(name)
  guest_ensure_init()
  if game.players[name] and game.players[name].connected then
    if global.guest_info[name].type == 'guest' then
      if global.guest_info[name].can_unlock then
        game.players[name].print{"patch-guest.you-have-been-set-as-guest-can-unlock"}
      else
        game.players[name].print{"patch-guest.you-have-been-set-as-guest"}
      end
    else
      game.players[name].print{"patch-guest.you-have-been-set-as-member"}
    end
    global.guest_info[name].notice_on_joined = false
  else
    global.guest_info[name].notice_on_joined = true
  end
end

function guest_set_as_guest(player_name, b, can_unlock)
  -- work around, non-admin cannot change group in script
  realm.next_tick(function()
    local group = guest_get_guest_permission_group()

    guest_ensure_init()
    global.guest_info[player_name] = global.guest_info[player_name] or {name=player_name}
    if b then
      global.guest_info[player_name].type = 'guest'
      global.guest_info[player_name].can_unlock = can_unlock

      if game.players[player_name] then
        local player = game.players[player_name]
        group.add_player(player)
        player.tag = "[guest]"
      end
    else
      global.guest_info[player_name].type = 'member'

      if game.players[player_name] then
        local player = game.players[player_name]
        group.remove_player(player_name)
        player.tag = ""
      end
    end

    guest_notice(player_name)
  end)
end

function guest_get_list(t)
  guest_ensure_init()

  local guests = {}
  
  for _, info in pairs(global.guest_info) do
    if info.type == t then
      table.insert(guests, info)
    end
  end

  return guests
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

  for _, name in ipairs(e.argv) do
    guest_set_as_guest(name, true, false)
    game.print{"patch-guest.set-as-guest", name, e.commander}
  end
end

realm.patches.guest.commands.member = function(e)
  if not e.by_admin then
    print_back(e, {"cant-run-command-not-admin", e.name})
    return
  end

  if not e.argv[1] then
    print_back(e, {"patch-guest.bad-command", "unguest"})
    return
  end

  for _, name in ipairs(e.argv) do
    guest_set_as_guest(name, false)
    game.print{"patch-guest.set-as-member", name, e.commander}
  end
end

realm.patches.guest.commands.guests = function(e)
  local players = guest_get_list('guest')
  print_back(e, {"patch-guest.guests-banner", #players})
  for _, p in ipairs(players) do
    local st, cu
    if not game.players[p.name] then
      st = {"patch-guest.not-in-game"}
    elseif game.players[p.name].connected then
      st = {"patch-guest.online"}
    else
      st = {"patch-guest.offline"}
    end
    if p.can_unlock then
      cu = {"patch-guest.can-unlock"}
    else
      cu = {"patch-guest.cannot-unlock"}
    end
    print_back(e, {"patch-guest.guest-info", p.name, st, cu})
  end
end

realm.patches.guest.commands.members = function(e)
  local players = guest_get_list('member')
  print_back(e, {"patch-guest.members-banner", #players})
  for _, p in ipairs(players) do
    local st, cu
    if not game.players[p.name] then
      st = {"patch-guest.not-in-game"}
    elseif game.players[p.name].connected then
      st = {"patch-guest.online"}
    else
      st = {"patch-guest.offline"}
    end
    print_back(e, {"patch-guest.member-info", p.name, st})
  end
end

realm.patches.guest.commands["new-player-as-guest"] = function(e)
  guest_ensure_init()

  if #e.argv ~= 0 and not e.by_admin then
    print_back(e, {"cant-run-command-not-admin", e.name})
    return
  end

  if e.argv[1] == "on" then
    global.new_player_as_guest = true
    local pass = e.argv[2]
    if pass then
      global.new_player_unlock_password = {}
      global.new_player_unlock_password.salt = tostring(math.random())
      -- a weak protection
      -- factorio lua is really too slow
      -- at least, better then plain password
      global.new_player_unlock_password.pass = sha1.hmac(global.new_player_unlock_password.salt, pass)
    else
      global.new_player_unlock_password = nil
    end
  elseif e.argv[1] == "off" then
    global.new_player_as_guest = false
  elseif e.argv[1] == nil then
    -- do nothing here
  else
    print_back(e, {"patch-guest.bad-command", e.name})
    return
  end

  if global.new_player_as_guest then
    game.print({"patch-guest.new-player-as-guest", {"patch-guest.on"}})
  else
    game.print({"patch-guest.new-player-as-guest", {"patch-guest.off"}})
  end
  if global.new_player_unlock_password then
    game.print({"patch-guest.unlock-password-status", {"patch-guest.on"}})
  else
    game.print({"patch-guest.unlock-password-status", {"patch-guest.off"}})
  end
end

realm.patches.guest.commands.unlock = function(e)
  if not e.player_index then
    print_back(e, {"patch-guest.cannot-run-in-terminal"})
    return
  end

  guest_ensure_init()
  local player = game.players[e.player_index]
  local info = global.guest_info[player.name]
  
  if info.type ~= 'guest' then
    print_back(e, {"patch-guest.not-a-guest"})
    return
  end

  if not info.can_unlock then
    print_back(e, {"patch-guest.cannot-unlock-by-password"})
    return
  end

  if not global.new_player_unlock_password then
    print_back(e, {"patch-guest.password-unlock-disabled"})
    return
  end

  if sha1.hmac(global.new_player_unlock_password.salt, e.argv[1]) ~= global.new_player_unlock_password.pass then
    print_back(e, {"patch-guest.password-error"})
    return
  end

  guest_set_as_guest(player.name, false)
  game.print{"patch-guest.set-as-member", player.name, "<password>"}
end

realm.patches.guest.on_player_created = function(e)
  guest_ensure_init()

  local player = game.players[e.player_index]
  if global.guest_info[player.name] then
    -- preordination
    local info = global.guest_info[player.name]
    if info.type == 'guest' then
      guest_set_as_guest(player.name, true, false)
    end
  else
    if global.new_player_as_guest then
      guest_set_as_guest(player.name, true, true)
    else
      guest_set_as_guest(player.name, false)
    end
  end
end

realm.patches.guest.on_player_joined_game = function(e)
  guest_ensure_init()

  local player = game.players[e.player_index]
  local info = global.guest_info[player.name]
  if info and info.notice_on_joined then
    guest_notice(player.name)
  end
end
