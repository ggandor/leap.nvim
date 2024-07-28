local api = vim.api
local function get_nodes()
  if not pcall(vim.treesitter.get_parser) then
    return nil, "No treesitter parser for this filetype."
  else
    local _1_ = vim.treesitter.get_node()
    if (nil ~= _1_) then
      local node = _1_
      local nodes = {node}
      local parent = node:parent()
      while parent do
        table.insert(nodes, parent)
        parent = parent:parent()
      end
      return nodes
    else
      return nil
    end
  end
end
local function nodes__3etargets(nodes)
  local linewise_3f = vim.fn.mode(true):match("V")
  local targets = {}
  local prev_range = {}
  for _, node in ipairs(nodes) do
    local startline, startcol, endline, endcol = node:range()
    if not (linewise_3f and (startline == endline)) then
      local endline_2a = endline
      local endcol_2a = endcol
      if (endcol == 0) then
        endline_2a = (endline - 1)
        endcol_2a = (#vim.fn.getline((endline_2a + 1)) + 1)
      else
      end
      local range
      if linewise_3f then
        range = {startline, endline_2a}
      else
        range = {startline, startcol, endline_2a, endcol_2a}
      end
      if vim.deep_equal(range, prev_range) then
        table.remove(targets)
      else
      end
      prev_range = range
      local target = {pos = {(startline + 1), (startcol + 1)}, endpos = {(endline_2a + 1), (endcol_2a + 1)}}
      table.insert(targets, target)
    else
    end
  end
  if (#targets > 0) then
    return targets
  else
    return nil
  end
end
local function get_targets()
  local nodes, err = get_nodes()
  if not nodes then
    return nil, err
  else
    return nodes__3etargets(nodes)
  end
end
local function select_range(target)
  local mode = vim.fn.mode(true)
  if mode:match("no?") then
    vim.cmd(("normal! " .. (mode:match("[V\22]") or "v")))
  else
  end
  if ((vim.fn.line("v") ~= vim.fn.line(".")) or (vim.fn.col("v") ~= vim.fn.col("."))) then
    vim.cmd("normal! o")
  else
  end
  vim.fn.cursor(unpack(target.pos))
  vim.cmd("normal! o")
  local endline, endcol = unpack(target.endpos)
  vim.fn.cursor(endline, (endcol - 1))
  vim.cmd("normal! o")
  return pcall(api.nvim__redraw, {flush = true})
end
local ns = api.nvim_create_namespace("")
local function clear_fill()
  return api.nvim_buf_clear_namespace(0, ns, 0, -1)
end
local function fill_cursor_pos(targets, start_idx)
  clear_fill()
  do
    local line,col = vim.fn.line("."), vim.fn.col(".")
    local line_str = vim.fn.getline(line)
    local ch_at_curpos = vim.fn.strpart(line_str, (col - 1), 1, true)
    local text
    if (ch_at_curpos == "") then
      text = " "
    else
      text = ch_at_curpos
    end
    local conflict_3f
    do
      local _13_ = targets[start_idx]
      if ((_G.type(_13_) == "table") and ((_G.type(_13_.pos) == "table") and (nil ~= _13_.pos[1]) and (nil ~= _13_.pos[2]))) then
        local line_2a = _13_.pos[1]
        local col_2a = _13_.pos[2]
        conflict_3f = ((line_2a == line) and (col_2a == col))
      else
        conflict_3f = nil
      end
    end
    local shift = 1
    if conflict_3f then
      local loop_3f = true
      local idx = (start_idx + 1)
      while loop_3f do
        local _15_ = targets[idx]
        if (_15_ == nil) then
          loop_3f = false
        elseif ((_G.type(_15_) == "table") and ((_G.type(_15_.pos) == "table") and (nil ~= _15_.pos[1]) and true)) then
          local line_2a = _15_.pos[1]
          local _ = _15_.pos[2]
          if (line_2a == line) then
            shift = (shift + 1)
            idx = (idx + 1)
          else
            loop_3f = false
          end
        else
        end
      end
    else
    end
    local _19_
    if conflict_3f then
      _19_ = (col + shift + -1)
    else
      _19_ = nil
    end
    api.nvim_buf_set_extmark(0, ns, (line - 1), (col - 1), {virt_text = {{text, "Visual"}}, virt_text_pos = "overlay", virt_text_win_col = _19_, hl_mode = "combine"})
  end
  return true
end
local function select(kwargs)
  local kwargs0 = (kwargs or {})
  local leap = require("leap")
  local op_mode_3f = vim.fn.mode(true):match("o")
  local inc_select_3f = not op_mode_3f
  local sk = vim.deepcopy(leap.opts.special_keys)
  sk.next_target = vim.fn.flatten(vim.list_extend({";"}, {sk.next_target}))
  sk.prev_target = vim.fn.flatten(vim.list_extend({","}, {sk.prev_target}))
  local ok_3f, context = pcall(require, "treesitter-context")
  local context_3f = (ok_3f and context.enabled())
  if context_3f then
    context.disable()
  else
  end
  local _22_
  if inc_select_3f then
    _22_ = ""
  else
    _22_ = nil
  end
  local _24_
  if inc_select_3f then
    _24_ = fill_cursor_pos
  else
    _24_ = nil
  end
  leap.leap({target_windows = {api.nvim_get_current_win()}, targets = get_targets, action = select_range, traversal = inc_select_3f, opts = vim.tbl_extend("keep", (kwargs0.opts or {}), {labels = _22_, on_beacons = _24_, virt_text_pos = "inline", special_keys = sk})})
  if inc_select_3f then
    clear_fill()
  else
  end
  if context_3f then
    return context.enable()
  else
    return nil
  end
end
return {select = select}
