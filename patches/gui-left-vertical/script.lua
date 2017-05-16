realm.patches.left_gui_vertical = {}

realm.patches.left_gui_vertical.on_player_created = function(e)
  local player = game.players[e.player_index]
  player.gui.left.direction = 'vertical'
end
