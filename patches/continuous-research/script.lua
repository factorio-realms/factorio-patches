realm.patches.continuous_research = {
  commands = {}
}

function realm.patches.continuous_research.on_research_finished(e)
  if not global.continuous_research_enabled or e.by_script then
    return
  end

  local research = e.research;
  local force = research.force;

  if not research.researched then
    realm.next_tick(function(research_name)
      force.current_research = research_name
    end, research.name)
  end
end

realm.patches.continuous_research.commands['continuous-research'] = function(e)
  if (e.argv[1] == 'on' or e.argv[1] == 'off') and not e.by_admin then
    print_back(e, {"patch-continuous-research.forbid"})
    return
  end

  if e.argv[1] == 'on' then
    global.continuous_research_enabled = true
  elseif e.argv[1] == 'off' then
    global.continuous_research_enabled = false
  end

  if global.continuous_research_enabled then
    game.print{"patch-continuous-research.option-on"}
  else
    game.print{"patch-continuous-research.option-off"}
  end
end
