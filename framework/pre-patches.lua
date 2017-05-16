realm = {
  config = {},
  patches = {},
}

--------------------------------------------------------------------------------
-- debug utils

function dump_to_string(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump_to_string(v) .. ','
    end
    return s .. '} '
  else
    if type(o) == 'string' then
      return '"' .. o .. '"'
    else
      return tostring(o)
    end
  end
end

function dump(o)
  print(dump_to_string(o))
  if game then
    game.print(dump_to_string(o))
  end
end

function debug(x)
  if realm.config.debug then
    dump(x)
  end
end

--------------------------------------------------------------------------------
-- argument deal utils

CONVERT_ARGUMENTS_STATES_MAP = {
  -- nil output self, -1 new word, >= 0 to another status
  -- "str" output special
  -- states: 0 normal, 1 in ", 2 in ', 10 - 12 after \
  [0] = {
    ['"'] = 1, ['\''] = 2, ['\\'] = 10, [' '] = -1, ['\r'] = -1, ['\n'] = -1,
  },
  [1] = {
    ['"'] = 0, ['\\'] = 11,
  },
  [2] = {
    ['\''] = 0, ['\\'] = 12,
  },
  [10] = {
    ['a'] = '\a', ['b'] = '\b', ['f'] = '\f', ['n'] = '\n', ['r'] = '\r',
    ['t'] = '\t', ['v'] = '\v', ['\\'] = '\\', ['\''] = '\'', ['"'] = '"',
  }
}
CONVERT_ARGUMENTS_STATES_MAP[11] = CONVERT_ARGUMENTS_STATES_MAP[10]
CONVERT_ARGUMENTS_STATES_MAP[12] = CONVERT_ARGUMENTS_STATES_MAP[10]

function convert_arguments(line)
  local s = 0
  local args = {}
  local arg = ""
  local status_map = CONVERT_ARGUMENTS_STATES_MAP

  for i = 1, line:len() do
    local x = status_map[s][line:sub(i,i)]
    if x == nil then
      arg = arg .. line:sub(i,i)
    elseif x == -1 then
      if arg ~= '' then
        table.insert(args, arg)
        arg = ''
      end
    elseif type(x) == 'string' then
      arg = arg .. x
      if s >= 10 then
        s = s - 10
      end
    elseif x >= 0 then
      s = x
    end
  end
  if arg ~= '' then
    table.insert(args, arg)
  end
  return args
end

function translate_localized_string(ls)
  -- a work around for console can not print localize string
  if type(ls) == 'table' then
    local x = LOCALE_EN[ls[1]]
    if not x then
      return "Unknown key: " .. tostring(ls[1])
    end

    x = x:gsub('__([0-9]+)__', function(idx)
      return ls[tonumber(idx) + 1]
    end)

    return x
  else
    return tostring(ls)
  end
end

function print_back(e, x)
  if game and e.player_index then
    local player = game.players[e.player_index]
    player.print(x)
  else
    print(translate_localized_string(x))
  end
end

function print_to(player, x)
  if not player or player == -1 then
    print(translate_localized_string(x))
  else
    if type(player) == 'number' then
      player = game.players[player]
    end
    player.print(x)
  end
end

--------------------------------------------------------------------------------
-- Basic data structure

Queue = {}

-- global do not support meta, so all method is not attached to instances
function Queue.new()
  local q = {}
  q.first = 0
  q.last = 0
  return q
end

function Queue.from_array(a)
  local q = {}

  for _, v in ipairs(a) do
    table.insert(q, v)
  end
  q.first = 0
  q.last = #q
  return q
end

function Queue.from_iter(iter)
  local q = {}

  for x in iter do
    table.insert(q, x)
  end
  q.first = 0
  q.last = #q
  return q
end

function Queue.length(q)
  return q.last - q.first
end

function Queue.push(q, x)
  q[q.last] = x
  q.last = q.last + 1
end

function Queue.pop(q)
  if q.last > q.first then
    local x = q[q.first]
    q[q.first] = nil
    q.first = q.first + 1
    return x
  end
  return nil
end

--------------------------------------------------------------------------------
-- String utils

function string.lines(self)
  return string.gmatch(string.gsub(self, '\n*$', '\n'), '[^\n]*\n')
end

--------------------------------------------------------------------------------
-- after all, hack script variable access
realm.patches.hacker = {
  on_event = {}
}

script_orig = script

script = {
  on_init = script_orig.on_init,  -- in fact, we can never receive this
  on_load = script_orig.on_load,
  on_configuration_changed = function(f) realm.patches.hacker.on_configuration_changed = f end,
  on_event = function(e, f) realm.patches.hacker.on_event[e] = f; remount_event(e) end,
  generate_event_name = script_orig.generate_event_name,
  get_event_handler = function(e) return realm.patches.hacker.on_event[e] end,
  raise_event = script_orig.raise_event,
}
