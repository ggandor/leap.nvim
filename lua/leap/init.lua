local function _1_(_, k)
  if (k == "opts") then
    return require("leap.opts").default
  elseif (k == "leap") then
    return require("leap.main").leap
  elseif (k == "state") then
    return require("leap.main").state
  elseif (k == "init_hl") then
    local function _2_(...)
      return require("leap.highlight"):init(...)
    end
    return _2_
  elseif (k == "setup") then
    return require("leap.user").setup
  elseif (k == "set_default_mappings") then
    return require("leap.user").set_default_mappings
  elseif (k == "init_highlight") then
    local function _3_(...)
      return require("leap.highlight"):init(...)
    end
    return _3_
  elseif (k == "create_default_mappings") then
    return require("leap.user").create_default_mappings
  elseif (k == "add_repeat_mappings") then
    return require("leap.user").add_repeat_mappings
  elseif (k == "add_default_mappings") then
    return require("leap.user").add_default_mappings
  elseif (k == "set_default_keymaps") then
    return require("leap.user").set_default_keymaps
  else
    return nil
  end
end
return setmetatable({}, {__index = _1_})
