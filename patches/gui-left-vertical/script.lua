realm.patches.left_gui_vertical = {}

realm.patches.left_gui_vertical.on_player_created = function(e)
  local player = game.players[e.player_index]
  player.gui.left.direction = 'vertical'
  if mod_gui then
    mod_gui.get_frame_flow(player).direction = 'vertical'
  end
end
