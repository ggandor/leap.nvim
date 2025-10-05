-- Code generated from fnl/leap/jump.fnl - do not edit directly.

local api = vim.api
local function cursor_before_eol_3f()
  return (vim.fn.search("\\_.", "Wn") ~= vim.fn.line("."))
end
local function cursor_before_eof_3f()
  return ((vim.fn.line(".") == vim.fn.line("$")) and (vim.fn.virtcol(".") == (vim.fn.virtcol("$") - 1)))
end
local function push_cursor_21(dir)
  local function _1_()
    if (dir == "fwd") then
      return "W"
    elseif (dir == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _1_())
end
local function add_offset_21(offset)
  if (offset < 0) then
    return push_cursor_21("bwd")
  elseif (offset > 0) then
    if not cursor_before_eol_3f() then
      push_cursor_21("fwd")
    else
    end
    if (offset > 1) then
      return push_cursor_21("fwd")
    else
      return nil
    end
  else
    return nil
  end
end
local function push_beyond_eof_21()
  local saved = vim.o.virtualedit
  vim.o.virtualedit = "onemore"
  vim.cmd("norm! l")
  local function _5_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _5_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _6_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_6_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eof_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_6_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21(_9_, _10_)
  local lnum = _9_[1]
  local col = _9_[2]
  local win = _10_["win"]
  local add_to_jumplist_3f = _10_["add-to-jumplist?"]
  local mode = _10_["mode"]
  local offset = _10_["offset"]
  local backward_3f = _10_["backward?"]
  local inclusive_3f = _10_["inclusive?"]
  local op_mode_3f = mode:match("o")
  if add_to_jumplist_3f then
    vim.cmd("norm! m`")
  else
  end
  if (win ~= api.nvim_get_current_win()) then
    api.nvim_set_current_win(win)
  else
  end
  api.nvim_win_set_cursor(0, {lnum, (col - 1)})
  if offset then
    add_offset_21(offset)
  else
  end
  if (op_mode_3f and inclusive_3f and not backward_3f) then
    simulate_inclusive_op_21(mode)
  else
  end
  if not op_mode_3f then
    pcall(api.nvim__redraw, {cursor = true})
    return force_matchparen_refresh()
  else
    return nil
  end
end
return {["jump-to!"] = jump_to_21}
