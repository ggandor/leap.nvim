-- Code generated from fnl/leap/util.fnl - do not edit directly.

local opts = require("leap.opts")
local api = vim.api
local filter = vim.tbl_filter
local lower = vim.fn.tolower
local upper = vim.fn.toupper
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
local function get_equivalence_class(ch)
  if opts.case_sensitive then
    return opts.eqv_class_of[ch]
  else
    return (opts.eqv_class_of[lower(ch)] or opts.eqv_class_of[upper(ch)])
  end
end
local function get_representative_char(ch)
  local ch_2a
  local _5_
  do
    local t_4_ = get_equivalence_class(ch)
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
    return lower(ch_2a)
  end
end
local function char_list_to_branching_regexp(chars)
  local prepare
  local function _8_(_241)
    if (_241 == "\n") then
      return "\\n"
    elseif (_241 == "\\") then
      return "\\\\"
    elseif (nil ~= _241) then
      local ch = _241
      return ch
    else
      return nil
    end
  end
  prepare = _8_
  local branches = vim.tbl_map(prepare, chars)
  return ("\\(" .. table.concat(branches, "\\|") .. "\\)")
end
local function char_to_search_pattern(char)
  return char_list_to_branching_regexp((get_equivalence_class(char) or {char}))
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
        local _11_, _12_ = get_char()
        if (_11_ == _3cbs_3e) then
          local function _13_()
            if (_7cseq_7c >= 2) then
              return seq:sub(1, dec(_7cseq_7c))
            else
              return seq
            end
          end
          return loop(_13_())
        elseif (_11_ == _3ccr_3e) then
          if (matching_rhs ~= "") then
            return accept(matching_rhs)
          elseif (_7cseq_7c == 1) then
            return accept(seq)
          else
            return loop(seq)
          end
        elseif (nil ~= _11_) then
          local ch = _11_
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
    local _18_ = loop(get_char())
    if (nil ~= _18_) then
      local input = _18_
      return input, prompt0
    else
      local _ = _18_
      return echo("")
    end
  end
end
return {inc = inc, dec = dec, clamp = clamp, echo = echo, ["get-cursor-pos"] = get_cursor_pos, get_enterable_windows = get_enterable_windows, get_focusable_windows = get_focusable_windows, ["char-to-search-pattern"] = char_to_search_pattern, ["get-representative-char"] = get_representative_char, ["get-char"] = get_char, ["get-char-keymapped"] = get_char_keymapped}
