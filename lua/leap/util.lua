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
local function get_cursor_pos()
  return {vim.fn.line("."), vim.fn.col(".")}
end
local function get_enterable_windows()
  local wins = api.nvim_tabpage_list_wins(0)
  local curr_win = api.nvim_get_current_win()
  local function _2_(_241)
    local config = api.nvim_win_get_config(_241)
    return (config.focusable and (config.relative == "") and (_241 ~= curr_win))
  end
  return filter(_2_, wins)
end
local function get_focusable_windows()
  return {vim.api.nvim_get_current_win(), unpack(get_enterable_windows())}
end
local function get_eqv_class(ch)
  if opts.case_sensitive then
    return opts.eqv_class_of[ch]
  else
    return (opts.eqv_class_of[vim.fn.tolower(ch)] or opts.eqv_class_of[vim.fn.toupper(ch)])
  end
end
local function get_representative_char(ch)
  local ch_2a
  local _5_
  do
    local t_4_ = get_eqv_class(ch)
    if (nil ~= t_4_) then
      t_4_ = t_4_[1]
    else
    end
    _5_ = t_4_
  end
  ch_2a = (_5_ or ch)
  if opts.case_sensitive then
    return ch_2a
  else
    return vim.fn.tolower(ch_2a)
  end
end
local _3cbs_3e = vim.keycode("<bs>")
local _3ccr_3e = vim.keycode("<cr>")
local _3cesc_3e = vim.keycode("<esc>")
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
    if ((1 <= _7cseq_7c) and (_7cseq_7c <= 5)) then
      echo_prompt(seq)
      local rhs_candidate = vim.fn.mapcheck(seq, "l")
      local rhs = vim.fn.maparg(seq, "l")
      if (rhs_candidate == "") then
        return accept(seq)
      elseif (rhs == rhs_candidate) then
        return accept(rhs)
      else
        local _9_, _10_ = get_input()
        if (_9_ == _3cbs_3e) then
          local function _11_()
            if (_7cseq_7c >= 2) then
              return seq:sub(1, dec(_7cseq_7c))
            else
              return seq
            end
          end
          return loop(_11_())
        elseif (_9_ == _3ccr_3e) then
          if (rhs ~= "") then
            return accept(rhs)
          elseif (_7cseq_7c == 1) then
            return accept(seq)
          else
            return loop(seq)
          end
        elseif (nil ~= _9_) then
          local ch = _9_
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
    local _16_ = loop(get_input())
    if (nil ~= _16_) then
      local _in = _16_
      return _in
    else
      local _ = _16_
      return echo("")
    end
  end
end
return {inc = inc, dec = dec, clamp = clamp, echo = echo, ["get-cursor-pos"] = get_cursor_pos, get_enterable_windows = get_enterable_windows, get_focusable_windows = get_focusable_windows, ["get-eqv-class"] = get_eqv_class, ["get-representative-char"] = get_representative_char, ["get-input"] = get_input, ["get-input-by-keymap"] = get_input_by_keymap}
