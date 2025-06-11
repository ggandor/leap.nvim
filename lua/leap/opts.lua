local M = {default = {equivalence_classes = {" \9\13\n"}, preview_filter = nil, safe_labels = {"s", "f", "n", "u", "t", "/", "S", "F", "N", "L", "H", "M", "U", "G", "T", "Z", "?"}, labels = {"s", "f", "n", "j", "k", "l", "h", "o", "d", "w", "e", "i", "m", "b", "u", "y", "v", "r", "g", "t", "a", "q", "p", "c", "x", "z", "/", "S", "F", "N", "J", "K", "L", "H", "O", "D", "W", "E", "I", "M", "B", "U", "Y", "V", "R", "G", "T", "A", "Q", "P", "C", "X", "Z", "?"}, special_keys = {next_target = "<enter>", prev_target = "<backspace>", next_group = "<space>", prev_group = "<backspace>"}, vim_opts = {["wo.scrolloff"] = 0, ["wo.sidescrolloff"] = 0, ["wo.conceallevel"] = 0, ["bo.modeline"] = false}, max_highlighted_traversal_targets = 10, substitute_chars = {}, case_sensitive = false, highlight_unlabeled_phase_one_targets = false}, current_call = {}}
local function _1_(self, key)
  local _2_ = self.current_call[key]
  if (_2_ == nil) then
    return self.default[key]
  elseif (nil ~= _2_) then
    local val = _2_
    local and_3_ = (type(val) == "table") and not vim.isarray(val)
    if and_3_ then
      local _5_
      do
        local t_4_ = getmetatable(val)
        if (nil ~= t_4_) then
          t_4_ = t_4_.merge
        else
        end
        _5_ = t_4_
      end
      and_3_ = (_5_ ~= false)
    end
    if and_3_ then
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
return setmetatable(M, {__index = _1_})
