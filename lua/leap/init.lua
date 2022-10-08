local function _1_(_, k)
  local _2_ = k
  if (_2_ == "opts") then
    return (require("leap.opts")).default
  elseif (_2_ == "leap") then
    return (require("leap.main")).leap
  elseif (_2_ == "state") then
    return (require("leap.main")).state
  elseif (_2_ == "setup") then
    return (require("leap.user")).setup
  elseif (_2_ == "add_default_mappings") then
    return (require("leap.user")).add_default_mappings
  elseif (_2_ == "init_highlight") then
    local function _3_(...)
      return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(require("leap.highlight"), "init-highlight", ...)
    end
    return _3_
  elseif (_2_ == "set_default_keymaps") then
    return (require("leap.user")).set_default_keymaps
  else
    return nil
  end
end
return setmetatable({}, {__index = _1_})
