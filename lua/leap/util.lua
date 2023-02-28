local opts = require("leap.opts")
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
local function get_cursor_pos()
  return {vim.fn.line("."), vim.fn.col(".")}
end
local function get_char_at(_2_, _4_)
  local _arg_3_ = _2_
  local line = _arg_3_[1]
  local byte_col = _arg_3_[2]
  local _arg_5_ = _4_
  local char_offset = _arg_5_["char-offset"]
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
  local wins = api.nvim_tabpage_list_wins(0)
  local curr_win = api.nvim_get_current_win()
  local curr_buf = api.nvim_get_current_buf()
  local function _7_(_241)
    return ((api.nvim_win_get_config(_241)).focusable and (_241 ~= curr_win))
  end
  return filter(_7_, wins)
end
local function get_eq_class_of(ch)
  if opts.case_sensitive then
    return opts.eq_class_of[ch]
  else
    return (opts.eq_class_of[vim.fn.tolower(ch)] or opts.eq_class_of[vim.fn.toupper(ch)])
  end
end
local function __3erepresentative_char(ch)
  local ch_2a
  local function _9_()
    local t_10_ = get_eq_class_of(ch)
    if (nil ~= t_10_) then
      t_10_ = (t_10_)[1]
    else
    end
    return t_10_
  end
  ch_2a = (_9_() or ch)
  if opts.case_sensitive then
    return ch_2a
  else
    return vim.fn.tolower(ch_2a)
  end
end
return {inc = inc, dec = dec, clamp = clamp, ["get-cursor-pos"] = get_cursor_pos, ["get-char-at"] = get_char_at, get_enterable_windows = get_enterable_windows, ["get-eq-class-of"] = get_eq_class_of, ["->representative-char"] = __3erepresentative_char}
