realm.patches.speed = {
  commands = {},
}

realm.patches.speed.commands.speed = function(e)
  if #e.argv == 0 then
    print_back(e, {"patch-speed.show", game.speed})
    return
  end

  if not e.by_admin then
    print_back(e, {"patch-speed.deny"})
    return
  end
  local speed = tonumber(e.argv[1])
  if not speed then
    print_back(e, {"patch-speed.invalid"})
    return
  end
  if not speed or speed < 0.05 or speed > 3 then
    print_back(e, {"patch-speed.out-of-range"})
    return
  end
  game.speed = speed
  game.print{"patch-speed.updated", speed, e.commander}
end
