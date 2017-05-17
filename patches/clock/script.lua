realm.patches.clock = {}

function clock_date_to_int(y, m, d)
  m = (m + 9) % 12
  y = y - math.floor(m/10)
  return 365*y + math.floor(y/4) - math.floor(y/100) + 
          math.floor(y/400) + math.floor((m*306 + 5)/10) + d - 1
end

function clock_int_to_date(g)
  local y = math.floor((10000*g + 14780)/3652425)
  local ddd = g - (365*y + math.floor(y/4) - math.floor(y/100) + math.floor(y/400))
  if ddd < 0 then
    y = y - 1
    ddd = g - (365*y + math.floor(y/4) - math.floor(y/100) + math.floor(y/400))
  end
  mi = math.floor((100*ddd + 52)/3060)
  mm = (mi + 2)%12 + 1
  y = y + math.floor((mi + 2)/12)
  dd = ddd - math.floor((mi*306 + 5)/10) + 1
  return y, mm, dd
end

function clock_format_2digit(x)
  if x < 10 then
    return '0' .. x
  else
    return '' .. x
  end
end

function clock_update_gui()
  local start = global.realm.clock_start_at
  local g = clock_date_to_int(start[1], start[2], start[3])
  g = g + math.floor((game.tick + 12500) / 25000)
  local y, m, d = clock_int_to_date(g)

  local t = math.floor(((game.tick + 12500) % 25000) * 24 * 60 / 25000)
  local hh = math.floor(t / 60)
  local mm = t % 60

  m = clock_format_2digit(m)
  d = clock_format_2digit(d)
  hh = clock_format_2digit(hh)
  mm = clock_format_2digit(mm)

  local str = {"patch-clock.yyyy-mm-dd-hh-mm", y, m, d, hh, mm}

  for _, p in pairs(game.connected_players) do
    local root = mod_gui and mod_gui.get_frame_flow(p) or p.gui.left
    if not root.clock then
      local clock = root.add{type='frame', name='clock'}
      clock.style.top_padding = 4
      clock.style.bottom_padding = 4
      clock.style.minimal_width = 200
      local layout = clock.add{type='table', name='layout', colspan=1}
      local label = layout.add{type='label', name='label'}
      label.style = 'caption_label_style'
    end
    local label = root.clock.layout.label
    label.caption = str
  end
end

function realm.patches.clock.on_init()
  if not global.realm.clock_start_at then
    global.realm.clock_start_at = {2067, 4, 1}
  end
end

function realm.patches.clock.on_tick()
  -- 17.36 ticks per game minute
  if game.tick % 17 == 3 then
    clock_update_gui()
  end
end
