-- Code generated from fnl/leap/opts.fnl - do not edit directly.

local M = {default = {equivalence_classes = {" \9\13\n"}, preview_filter = nil, safe_labels = "sfnut/SFNLHMUGTZ?", labels = ("sfnjklhodweimbuyvrgtaqpcxz/" .. "SFNJKLHODWEIMBUYVRGTAQPCXZ?"), keys = {next_target = "<enter>", prev_target = "<backspace>", next_group = "<space>", prev_group = "<backspace>"}, vim_opts = {["wo.scrolloff"] = 0, ["wo.sidescrolloff"] = 0, ["wo.conceallevel"] = 0, ["bo.modeline"] = false}, max_highlighted_traversal_targets = 10, substitute_chars = {}, case_sensitive = false, highlight_unlabeled_phase_one_targets = false}, current_call = {}}
local function _1_(self, key_2a)
  local key
  if (key_2a == "special_keys") then
    key = "keys"
  else
    local _ = key_2a
    key = key_2a
  end
  return self[key]
end
setmetatable(M.default, {__index = _1_})
local function _3_(self, key_2a)
  local key
  if (key_2a == "special_keys") then
    key = "keys"
  else
    local _ = key_2a
    key = key_2a
  end
  local _5_ = self.current_call[key]
  if (_5_ == nil) then
    return rawget(self.default, key)
  elseif (nil ~= _5_) then
    local val = _5_
    local and_6_ = (type(val) == "table") and not vim.isarray(val)
    if and_6_ then
      local _8_
      do
        local t_7_ = getmetatable(val)
        if (nil ~= t_7_) then
          t_7_ = t_7_.merge
        else
        end
        _8_ = t_7_
      end
      and_6_ = (_8_ ~= false)
    end
    if and_6_ then
      for k, v in pairs(self.default[key]) do
        if (val[k] == nil) then
          val[k] = v
        else
        end
      end
      return setmetatable(val, {merge = false})
    else
      return val
    end
  else
    return nil
  end
end
return setmetatable(M, {__index = _3_})
