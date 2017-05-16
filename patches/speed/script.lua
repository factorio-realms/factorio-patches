realm.patches.speed = {
  commands = {},
}

realm.patches.speed.commands.speed = function(e)
  if not e.by_admin then
    print_back(e, {"patch-speed.deny"})
  end
  local speed = tonumber(e.argv[1])
  if not speed then
    print_back(e, {"patch-speed.invalid"})
  end
  if not speed or speed < 0.05 or speed > 10 then
    print_back(e, {"patch-speed.out-of-range"})
    return
  end
  game.speed = speed
  if e.player_index then
    local player = game.players[e.player_index]
    game.print{"patch-speed.updated", speed, player.name}
  else
    -- keep silent when speed is updated by console
    print_to(-1, {"patch-speed.updated", speed, "console"})
  end
end
