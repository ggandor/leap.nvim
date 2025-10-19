-- Code generated from fnl/leap/util.fnl - do not edit directly.

local api = vim.api
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
  return vim.tbl_filter(_2_, wins)
end
local function get_focusable_windows()
  return {vim.api.nvim_get_current_win(), unpack(get_enterable_windows())}
end
local function get_horizontal_bounds()
  local window_width = api.nvim_win_get_width(0)
  local textoff = vim.fn.getwininfo(api.nvim_get_current_win())[1].textoff
  local offset_in_win = (vim.fn.wincol() - 1)
  local offset_in_editable_win = (offset_in_win - textoff)
  local left_bound = (vim.fn.virtcol(".") - offset_in_editable_win)
  local right_bound = (left_bound + (window_width - textoff - 1))
  return {left_bound, right_bound}
end
local _3cbs_3e = vim.keycode("<bs>")
local _3ccr_3e = vim.keycode("<cr>")
local _3cesc_3e = vim.keycode("<esc>")
local function get_char()
  local ok_3f, ch = pcall(vim.fn.getcharstr)
  if (ok_3f and (ch ~= _3cesc_3e)) then
    return ch
  else
    return nil
  end
end
local function get_char_keymapped(prompt)
  local prompt0 = (prompt or ">")
  local function echo_prompt(seq)
    return api.nvim_echo({{prompt0}, {(seq or ""), "ErrorMsg"}}, false, {})
  end
  local function accept(ch)
    prompt0 = (prompt0 .. ch)
    echo_prompt()
    return ch
  end
  local function loop(seq)
    local _7cseq_7c = #(seq or "")
    if ((1 <= _7cseq_7c) and (_7cseq_7c <= 5)) then
      echo_prompt(seq)
      local candidate_rhs = vim.fn.mapcheck(seq, "l")
      local matching_rhs = vim.fn.maparg(seq, "l")
      if (candidate_rhs == "") then
        return accept(seq)
      elseif (matching_rhs == candidate_rhs) then
        return accept(matching_rhs)
      else
        local _4_, _5_ = get_char()
        if (_4_ == _3cbs_3e) then
          local function _6_()
            if (_7cseq_7c >= 2) then
              return seq:sub(1, dec(_7cseq_7c))
            else
              return seq
            end
          end
          return loop(_6_())
        elseif (_4_ == _3ccr_3e) then
          if (matching_rhs ~= "") then
            return accept(matching_rhs)
          elseif (_7cseq_7c == 1) then
            return accept(seq)
          else
            return loop(seq)
          end
        elseif (nil ~= _4_) then
          local ch = _4_
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
    return get_char()
  else
    echo_prompt()
    local _11_ = loop(get_char())
    if (nil ~= _11_) then
      local input = _11_
      return input, prompt0
    else
      local _ = _11_
      return echo("")
    end
  end
end
return {clamp = clamp, echo = echo, ["get-cursor-pos"] = get_cursor_pos, get_enterable_windows = get_enterable_windows, get_focusable_windows = get_focusable_windows, ["get-horizontal-bounds"] = get_horizontal_bounds, ["get-char"] = get_char, ["get-char-keymapped"] = get_char_keymapped}
