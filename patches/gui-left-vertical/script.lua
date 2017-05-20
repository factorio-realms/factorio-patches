realm.patches.left_gui_vertical = {}

function left_gui_vertical_patch(player)
  player.gui.left.direction = 'vertical'
  if mod_gui then
    mod_gui.get_frame_flow(player).direction = 'vertical'
  end
end

function realm.patches.left_gui_vertical.on_init()
  for _, p in pairs(game.players) do
    left_gui_vertical_patch(p)
  end
end

function realm.patches.left_gui_vertical.on_player_created(e)
  local player = game.players[e.player_index]
  left_gui_vertical_patch(player)
end
