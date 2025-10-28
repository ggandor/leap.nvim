-- Code generated from fnl/leap/jump.fnl - do not edit directly.

local api = vim.api
local function cursor_before_eol_3f()
  return (vim.fn.virtcol(".") == (vim.fn.virtcol("$") - 1))
end
local function cursor_before_eof_3f()
  return (cursor_before_eol_3f and (vim.fn.line(".") == vim.fn.line("$")))
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
local function push_beyond_eol_21()
  local saved = vim.o.virtualedit
  vim.o.virtualedit = "onemore"
  vim.cmd("norm! l")
  local function _2_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _2_, once = true})
end
local function add_offset_21(offset)
  if (offset < 0) then
    return push_cursor_21("bwd")
  elseif (offset > 0) then
    if cursor_before_eol_3f() then
      push_beyond_eol_21()
    else
      push_cursor_21("fwd")
    end
    if (offset > 1) then
      if cursor_before_eol_3f() then
        return push_beyond_eol_21()
      else
        return push_cursor_21("fwd")
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function simulate_inclusive_op_21(mode)
  local _7_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_7_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eol_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_7_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21(_10_, kwargs)
  local lnum = _10_[1]
  local col = _10_[2]
  local win = kwargs["win"]
  local add_to_jumplist_3f = kwargs["add-to-jumplist?"]
  local mode = kwargs["mode"]
  local offset = kwargs["offset"]
  local backward_3f = kwargs["backward?"]
  local inclusive_3f = kwargs["inclusive?"]
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
