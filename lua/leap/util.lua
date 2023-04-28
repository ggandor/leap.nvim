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
local function echo(msg)
  return api.nvim_echo({{msg}}, false, {})
end
local function replace_keycodes(s)
  return api.nvim_replace_termcodes(s, true, false, true)
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
  local function _7_(_241)
    local config = api.nvim_win_get_config(_241)
    return (config.focusable and (config.relative == "") and (_241 ~= curr_win))
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
local _3cbs_3e = replace_keycodes("<bs>")
local _3ccr_3e = replace_keycodes("<cr>")
local _3cesc_3e = replace_keycodes("<esc>")
local function get_input()
  local ok_3f, ch = pcall(vim.fn.getcharstr)
  if (ok_3f and (ch ~= _3cesc_3e)) then
    return ch
  else
    return nil
  end
end
local function get_input_by_keymap(prompt)
  local function echo_prompt(seq)
    return api.nvim_echo({{prompt.str}, {(seq or ""), "ErrorMsg"}}, false, {})
  end
  local function accept(ch)
    prompt.str = (prompt.str .. ch)
    echo_prompt()
    return ch
  end
  local function loop(seq)
    local _7cseq_7c = #(seq or "")
    if (1 <= _7cseq_7c) and (_7cseq_7c <= 5) then
      echo_prompt(seq)
      local rhs_candidate = vim.fn.mapcheck(seq, "l")
      local rhs = vim.fn.maparg(seq, "l")
      if (rhs_candidate == "") then
        return accept(seq)
      elseif (rhs == rhs_candidate) then
        return accept(rhs)
      else
        local _14_, _15_ = get_input()
        if (_14_ == _3cbs_3e) then
          local function _16_()
            if (_7cseq_7c >= 2) then
              return seq:sub(1, dec(_7cseq_7c))
            else
              return seq
            end
          end
          return loop(_16_())
        elseif (_14_ == _3ccr_3e) then
          if (rhs ~= "") then
            return accept(rhs)
          elseif (_7cseq_7c == 1) then
            return accept(seq)
          else
            return loop(seq)
          end
        elseif (nil ~= _14_) then
          local ch = _14_
          return loop((seq .. ch))
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  if (vim.bo.iminsert ~= 1) then
    return get_input()
  else
    echo_prompt()
    local _21_ = loop(get_input())
    if (nil ~= _21_) then
      local _in = _21_
      return _in
    elseif true then
      local _ = _21_
      return echo("")
    else
      return nil
    end
  end
end
return {inc = inc, dec = dec, clamp = clamp, echo = echo, ["replace-keycodes"] = replace_keycodes, ["get-cursor-pos"] = get_cursor_pos, ["get-char-at"] = get_char_at, get_enterable_windows = get_enterable_windows, ["get-eq-class-of"] = get_eq_class_of, ["->representative-char"] = __3erepresentative_char, ["get-input"] = get_input, ["get-input-by-keymap"] = get_input_by_keymap}
