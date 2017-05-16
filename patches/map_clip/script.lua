realm.patches.map_clip = {
  commands = {}
}

realm.patches.map_clip.on_init = function()
  if not global.map_clip then
    global.map_clip = {
      guards_queue = Queue.new(),
      guards_hash = {},
    }
  end
end

function map_clip_is_area_needed(surface, pos)
  if math.abs(pos.x) <= 7 and math.abs(pos.y) <= 7 then
    return true
  end
  local point = {pos.x * 32 + 16, pos.y * 32 + 16}
  if surface.get_pollution(point) > 0.001 then
    return true
  end
  for _, f in pairs(game.forces) do
    if f.is_chunk_charted(surface, pos) then
      return true
    end
  end
  for _, p in pairs(game.connected_players) do
    if p.surface.name == surface.name then
      local px = math.floor(p.position.x / 32)
      local py = math.floor(p.position.y / 32)
      if math.abs(px - pos.x) <= 3 and math.abs(py - pos.y) <= 3 then
        return true
      end
    end
  end
  return false
end

function map_clip_clean_chunk(surface, pos)
  local area = {{pos.x * 32, pos.y * 32}, {pos.x * 32 + 32, pos.y * 32 + 32}}
  for _, e in pairs(surface.find_entities_filtered({area=area})) do
    if e.name ~= 'player' then
      e.destroy()
    end
  end
end

realm.patches.map_clip.on_chunk_generated = function(event)
  local area = event.area
  local pos = {x=area.left_top.x / 32, y=area.left_top.y / 32}
  if not map_clip_is_area_needed(event.surface, pos) then
    map_clip_clean_chunk(event.surface, pos)

    local q = global.map_clip.guards_queue
    Queue.push(q, {surface=event.surface.name, pos=pos})
    local h = global.map_clip.guards_hash
    h[event.surface.name .. '#' .. pos.x .. ',' .. pos.y] = true

    debug("guard chunk {" .. pos.x .. "," .. pos.y .. "} queue length: " .. Queue.length(q))
  else
    debug("chunk {" .. pos.x .. "," .. pos.y .. "} generated")
    for _, f in pairs(game.forces) do
      if f.is_chunk_charted(event.surface, pos) then
        f.chart(event.surface, {{pos.x * 32 + 10, pos.y * 32 + 10}, {pos.x * 32 + 11, pos.y * 32 + 11}})
      end
    end
  end
end

function map_clip_regenerate(surface, pos)
  local h = global.map_clip.guards_hash
  if not h[surface.name .. '#' .. pos.x .. ',' .. pos.y] then
    return
  end

  debug("regenerate chunk {" .. pos.x .. "," .. pos.y .. "}")
  surface.set_chunk_generated_status(pos, defines.chunk_generated_status.tiles)

  h[surface.name .. '#' .. pos.x .. ',' .. pos.y] = nil
end

function map_clip_patrol()
  local q = global.map_clip.guards_queue
  local x = Queue.pop(q)
  if not x then
    return
  end
  local surface = game.surfaces[x.surface]
  if not surface then
    return
  end

  local h = global.map_clip.guards_hash
  if not h[surface.name .. '#' .. x.pos.x .. ',' .. x.pos.y] then
    -- not in guard now, ignore
  elseif map_clip_is_area_needed(surface, x.pos) then
    map_clip_regenerate(surface, x.pos)
  else
    map_clip_clean_chunk(surface, x.pos)
    Queue.push(q, x)
  end
end

realm.patches.map_clip.on_tick = function()
  map_clip_patrol()

  if game.tick % 61 == 37 then
    for _, p in pairs(game.connected_players) do
      local px = math.floor(p.position.x / 32)
      local py = math.floor(p.position.y / 32)
      for dx=-3,3 do
        for dy=-2,2 do
          map_clip_regenerate(p.surface, {x=px+dx, y=py+dy})
        end
      end
    end
  end
end

realm.patches.map_clip.commands["map-clip-status"] = function(e)
  local clips = {}
  for k, _ in pairs(global.map_clip.guards_hash) do
    local sname = k:gsub('#.*', '')
    if clips[sname] then
      clips[sname] = clips[sname] + 1
    else
      clips[sname] = 1
    end
  end
  for _, surface in pairs(game.surfaces) do
    local gen = 0
    for chunk in surface.get_chunks() do
      gen = gen + 1
    end
    local cliped = clips[surface.name] or 0
    print_back(e, {"patch-map-clip.report", surface.name, gen, gen - cliped, cliped})
  end
end
