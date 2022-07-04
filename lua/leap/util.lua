local api = vim.api
local filter = vim.tbl_filter
local function inc(x)
  return (x + 1)
end
local function dec(x)
  return (x - 1)
end
local function clamp(x, min, max)
  if (x < min) then
    return min
  elseif (x > max) then
    return max
  else
    return x
  end
end
local function echo(msg)
  return api.nvim_echo({{msg}}, false, {})
end
local function replace_keycodes(s)
  return api.nvim_replace_termcodes(s, true, false, true)
end
local function get_cursor_pos()
  return {vim.fn.line("."), vim.fn.col(".")}
end
local function push_cursor_21(direction)
  local function _3_()
    local _2_ = direction
    if (_2_ == "fwd") then
      return "W"
    elseif (_2_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _3_())
end
local function get_char_at(_5_, _7_)
  local _arg_6_ = _5_
  local line = _arg_6_[1]
  local byte_col = _arg_6_[2]
  local _arg_8_ = _7_
  local char_offset = _arg_8_["char-offset"]
  local line_str = vim.fn.getline(line)
  local char_idx = vim.fn.charidx(line_str, (byte_col - 1))
  local char_nr = vim.fn.strgetchar(line_str, (char_idx + (char_offset or 0)))
  if (char_nr ~= -1) then
    return vim.fn.nr2char(char_nr)
  else
    return nil
  end
end
local function get_enterable_windows()
  local mode = api.nvim_get_mode().mode
  local wins = api.nvim_tabpage_list_wins(0)
  local curr_win = api.nvim_get_current_win()
  local curr_buf = api.nvim_get_current_buf()
  local visual_7cop_mode_3f = (mode ~= "n")
  local function _10_(_241)
    return ((api.nvim_win_get_config(_241)).focusable and (_241 ~= curr_win) and not (visual_7cop_mode_3f and (api.nvim_win_get_buf(_241) ~= curr_buf)))
  end
  return filter(_10_, wins)
end
return {inc = inc, dec = dec, clamp = clamp, echo = echo, ["replace-keycodes"] = replace_keycodes, ["get-cursor-pos"] = get_cursor_pos, ["push-cursor!"] = push_cursor_21, ["get-char-at"] = get_char_at, get_enterable_windows = get_enterable_windows}
