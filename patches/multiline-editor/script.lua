realm.patches.multiline_editor = {}

function multiline_editor_create_line(parent, str)
  local line = parent.add{type='flow', direction='horizontal'}
  local input = line.add{type='textfield', text=str, style='console_input_textfield_style', name='editor'}
  input.style.minimal_width = 600
  input.style.maximal_width = 600
  input.style.minimal_height = 30
  local a = line.add{type='button', name='multiline-editor-add-line', caption='+', style='slot_button_style'}
  local b = line.add{type='button', name='multiline-editor-remove-line', caption='-', style='small_slot_button_style'}
  a.style.minimal_width = 30
  a.style.maximal_width = 30
  a.style.minimal_height = 30
  a.style.maximal_height = 30
  a.style.left_padding = 2
  b.style.minimal_width = 30
  b.style.maximal_width = 30
  b.style.minimal_height = 30
  b.style.maximal_height = 30
  b.style.left_padding = 2
end

function multiline_editor_show(p, opt, callback)
  local editor = p.gui.center.add{type='frame', name='multiline-editor'}
  local layout = editor.add{type='table', name='layout', direction='vertical', colspan=1}
  local title = layout.add{type='label', name='title', caption=opt.caption}
  title.style = 'caption_label_style'
  title.style.font = 'default-large-semibold'

  if opt.message then
    layout.add{type='label', name='information', caption=opt.msg}
  end

  local body = layout.add{type='scroll-pane', name='body'}
  body.style.minimal_height = 300
  body.style.maximal_height = 300
  local text = opt.text or ""
  for str in text:lines() do
    str = str:gsub("\n", "")
    multiline_editor_create_line(body, str)
  end

  local hlayout = layout.add{type='flow', name='hlayout', direction='horizontal'}
  hlayout.add{type='button', name='multiline-editor-ok', caption={'patch-multiline-editor.ok'}, style='dialog_button_style'}
  hlayout.add{type='button', name='multiline-editor-cancel', caption={'patch-multiline-editor.cancel'}, style='dialog_button_style'}

  global.multiline_editor_callback = global.multiline_editor_callback or {}
  global.multiline_editor_callback[p.index] = callback
end

function multiline_editor_find_ancestor(e, name)
  while e do
    if e.name == name then
      return e
    end
    e = e.parent
  end
  return nil
end

function realm.patches.multiline_editor.on_gui_click(e)
  if e.element.name == 'multiline-editor-add-line' then
    local line = e.element.parent
    local body = line.parent
    local line_no
    for no, l in ipairs(body.children) do
      if l == line then
        line_no = no
        break
      end
    end
    if not line_no then
      return
    end
    multiline_editor_create_line(body, "")
    for i = 1, #body.children - line_no - 1 do
      multiline_editor_create_line(body, body.children[line_no + 1].editor.text)
      body.children[line_no + 1].destroy()
    end
  elseif e.element.name == 'multiline-editor-remove-line' then
    local line = e.element.parent
    local body = line.parent
    local line_no
    for no, l in ipairs(body.children) do
      if l == line then
        line_no = no
        break
      end
    end
    if not line_no then
      return
    end
    body.children[line_no].destroy()
    if #body.children == 0 then
      multiline_editor_create_line(body, "")
    end
  elseif e.element.name == 'multiline-editor-ok' then
    local str = ""
    local editor = multiline_editor_find_ancestor(e.element, 'multiline-editor')
    local body = editor.layout.body
    for idx, line in ipairs(body.children) do
      str = str .. line.editor.text
      if idx ~= #body.children then
        str = str .. "\n"
      end
    end
    local callback = global.multiline_editor_callback[e.player_index]
    global.multiline_editor_callback[e.player_index] = nil
    editor.destroy()
    if callback then
      callback{player_index=e.player_index, text=str}
    end
  elseif e.element.name == 'multiline-editor-cancel' then
    local editor = multiline_editor_find_ancestor(e.element, 'multiline-editor')
    editor.destroy()
    global.multiline_editor_callback[e.player_index] = nil
  end
end
