realm.patches.welcome = {
  commands = {}
}

realm.patches.welcome.on_player_joined_game = function(e)
  local player = game.players[e.player_index]

  if global.welcome then
    for str in global.welcome:lines() do
      str = str:gsub('@NAME@', player.name)
      print_back(e, {"", str})
    end
  end
end

realm.patches.welcome.commands.welcome = function(e)
  if not e.argv[1] then
    print_back(e, {"patch-welcome.bad-command"})
    return
  end
  if (e.argv[1] == "set" or e.argv[1] == "clear") and not e.by_admin then
    print_back(e, {"patch-welcome.not-allowed"})
    return
  end
  if e.argv[1] == "set" then
    if not e.argv[2] then
      print_back(e, {"patch-welcome.bad-command"})
      return
    end
    global.welcome = e.argv[2]
    print_back(e, {"patch-welcome.updated"})
  elseif e.argv[1] == "clear" then
    global.welcome = nil
    print_back(e, {"patch-welcome.cleared"})
  elseif e.argv[1] == "show" then
    if global.welcome then
      realm.patches.welcome.on_player_joined_game(e)
    else
      print_back(e, {"patch-welcome.no-welcome"})
    end
  end
end
