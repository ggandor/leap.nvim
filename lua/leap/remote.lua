local api = vim.api
local function default_jumper()
  local util = require("leap.util")
  local leap = require("leap").leap
  return leap({opts = {safe_labels = ""}, target_windows = util.get_focusable_windows()})
end
local function action(kwargs)
  local _local_1_ = (kwargs or {})
  local jumper = _local_1_["jumper"]
  local input = _local_1_["input"]
  local jumper0 = (jumper or default_jumper)
  local state = {mode = vim.fn.mode(true), count = vim.v.count, register = vim.v.register}
  local src_win = vim.fn.win_getid()
  local saved_view = vim.fn.winsaveview()
  local anch_ns = api.nvim_create_namespace("")
  local anch_id = api.nvim_buf_set_extmark(0, anch_ns, (saved_view.lnum - 1), saved_view.col, {})
  local function restore()
    if (vim.fn.win_getid() ~= src_win) then
      api.nvim_set_current_win(src_win)
    else
    end
    vim.fn.winrestview(saved_view)
    local anch_pos = api.nvim_buf_get_extmark_by_id(0, anch_ns, anch_id, {})
    api.nvim_win_set_cursor(0, {(anch_pos[1] + 1), anch_pos[2]})
    return api.nvim_buf_clear_namespace(0, anch_ns, 0, -1)
  end
  local function cancels_3f(key)
    local mode = vim.fn.mode(true)
    return ((key == vim.keycode("<esc>")) or (key == vim.keycode("<c-c>")) or (((mode == "v") or (mode == "V") or (mode == "\22")) and (key == mode)))
  end
  local function restore_on_finish()
    local op_canceled_3f = false
    local ns_id
    local function _3_(key, _)
      if cancels_3f(key) then
        op_canceled_3f = true
        return nil
      else
        return nil
      end
    end
    ns_id = vim.on_key(_3_)
    local function _5_()
      restore()
      vim.on_key(nil, ns_id)
      if not op_canceled_3f then
        return api.nvim_exec_autocmds("User", {pattern = "RemoteOperationDone", data = state})
      else
        return nil
      end
    end
    return api.nvim_create_autocmd("ModeChanged", {pattern = "*:n", once = true, callback = vim.schedule_wrap(_5_)})
  end
  local function feed(seq)
    api.nvim_feedkeys(seq, "n", false)
    if input then
      return api.nvim_feedkeys(input, "", false)
    else
      return nil
    end
  end
  if state.mode:match("no") then
    api.nvim_feedkeys(vim.keycode("<C-\\><C-N>"), "nx", false)
    api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
  elseif state.mode:match("[vV\22]") then
    api.nvim_feedkeys(state.mode, "n", false)
  else
  end
  local function _9_()
    jumper0()
    vim.cmd("norm! m`")
    if state.mode:match("no") then
      local count
      if (state.count > 0) then
        count = state.count
      else
        count = ""
      end
      local reg = ("\"" .. state.register)
      local force = state.mode:sub(3)
      feed((count .. reg .. vim.v.operator .. force))
    elseif state.mode:match("[vV\22]") then
      feed(state.mode)
    else
      feed("v")
    end
    return restore_on_finish()
  end
  return vim.schedule(_9_)
end
return {action = action}
