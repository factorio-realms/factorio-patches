realm.patches.assist = {
  commands = {}
}

realm.patches.assist.commands['print-names'] = function(e)
  if not e.player_index then
    print_back(e, {'patch-assist.cannot-run-in-terminal'})
    return
  end

  local player = game.players[e.player_index]

  print_back(e, {'patch-assist.dash'})

  if player.selected then
    print_back(e, {'patch-assist.selected', player.selected.name})
  else
    print_back(e, {'patch-assist.no-selected'})
  end

  if player.cursor_stack and player.cursor_stack.valid_for_read then
    print_back(e, {'patch-assist.cursor-stack', player.cursor_stack.name})
  else
    print_back(e, {'patch-assist.no-cursor-stack'})
  end

  if player.force.current_research then
    print_back(e, {'patch-assist.current-research', player.force.current_research.name})
  else
    print_back(e, {'patch-assist.no-research'})
  end
end
