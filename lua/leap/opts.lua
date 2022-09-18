local current_call = {}
local default = {max_aot_targets = nil, equivalence_classes = {" \9\13\n"}, safe_labels = {"s", "f", "n", "u", "t", "/", "S", "F", "N", "L", "H", "M", "U", "G", "T", "?", "Z"}, labels = {"s", "f", "n", "j", "k", "l", "h", "o", "d", "w", "e", "m", "b", "u", "y", "v", "r", "g", "t", "c", "x", "/", "z", "S", "F", "N", "J", "K", "L", "H", "O", "D", "W", "E", "M", "B", "U", "Y", "V", "R", "G", "T", "C", "X", "?", "Z"}, special_keys = {repeat_search = "<enter>", next_aot_match = "<enter>", next_match = {";", "<enter>"}, prev_match = {",", "<tab>"}, next_group = "<space>", prev_group = "<tab>", multi_accept = "<enter>", multi_revert = "<backspace>"}, highlight_unlabeled = false, case_sensitive = false}
local function _1_(self, k)
  local _2_ = self.current_call[k]
  if (nil ~= _2_) then
    local v = _2_
    return v
  elseif true then
    local _ = _2_
    return self.default[k]
  else
    return nil
  end
end
return setmetatable({current_call = current_call, default = default}, {__index = _1_})
