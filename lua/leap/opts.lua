local M = {default = {preview_filter = nil, max_highlighted_traversal_targets = 10, equivalence_classes = {" \9\13\n"}, substitute_chars = {}, safe_labels = {"s", "f", "n", "u", "t", "/", "S", "F", "N", "L", "H", "M", "U", "G", "T", "Z", "?"}, labels = {"s", "f", "n", "j", "k", "l", "h", "o", "d", "w", "e", "i", "m", "b", "u", "y", "v", "r", "g", "t", "a", "q", "p", "c", "x", "z", "/", "S", "F", "N", "J", "K", "L", "H", "O", "D", "W", "E", "I", "M", "B", "U", "Y", "V", "R", "G", "T", "A", "Q", "P", "C", "X", "Z", "?"}, special_keys = {next_target = "<enter>", prev_target = "<backspace>", next_group = "<space>", prev_group = "<backspace>"}, case_sensitive = false, highlight_unlabeled_phase_one_targets = false, keep_conceallevel = false}, current_call = {}}
local function _1_(self, key)
  local _2_ = self.current_call[key]
  if (_2_ == nil) then
    return self.default[key]
  elseif (nil ~= _2_) then
    local val = _2_
    return val
  else
    return nil
  end
end
return setmetatable(M, {__index = _1_})
