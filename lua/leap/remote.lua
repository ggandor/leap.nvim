-- Code generated from fnl/leap/remote.fnl - do not edit directly.

local api = vim.api
local function action(kwargs)
  local kwargs0 = (kwargs or {})
  local jumper = kwargs0["jumper"]
  local input = kwargs0["input"]
  local use_count_3f = kwargs0["count"]
  local use_count_3f0 = (use_count_3f ~= false)
  local mode = vim.fn.mode(true)
  local state = {args = kwargs0, mode = mode, count = vim.v.count, register = vim.v.register}
  local src_win = vim.fn.win_getid()
  local saved_view = vim.fn.winsaveview()
  local anch_ns = api.nvim_create_namespace("")
  local anch_id = api.nvim_buf_set_extmark(0, anch_ns, (saved_view.lnum - 1), saved_view.col, {})
  local function to_normal_mode()
    if state.mode:match("no") then
      api.nvim_feedkeys(vim.keycode("<C-\\><C-N>"), "nx", false)
      return api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
    elseif state.mode:match("[vV\22]") then
      return api.nvim_feedkeys(state.mode, "n", false)
    else
      return nil
    end
  end
  local function default_jumper()
    local util = require("leap.util")
    local leap = require("leap").leap
    local _2_
    if (input or (mode ~= "n")) then
      _2_ = {safe_labels = ""}
    else
      _2_ = nil
    end
    return leap({opts = _2_, windows = util.get_focusable_windows()})
  end
  local jumper0 = (jumper or default_jumper)
  local function cursor_moved_3f()
    return not ((vim.fn.win_getid() == src_win) and (vim.fn.line(".") == saved_view.lnum) and (vim.fn.col(".") == (saved_view.col + 1)))
  end
  local function back_to_pending_action()
    if state.mode:match("o") then
      local count
      if (use_count_3f0 and (state.count > 0)) then
        count = state.count
      else
        count = ""
      end
      local register = ("\"" .. state.register)
      local op = vim.v.operator
      local force = state.mode:sub(3)
      return api.nvim_feedkeys((count .. register .. op .. force), "n", false)
    elseif state.mode:match("[vV\22]") then
      return api.nvim_feedkeys(state.mode, "n", false)
    else
      return nil
    end
  end
  local function restore_cursor()
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
    local mode0 = vim.fn.mode(true)
    return ((key == vim.keycode("<esc>")) or (key == vim.keycode("<c-c>")) or (((mode0 == "v") or (mode0 == "V") or (mode0 == "\22")) and (key == mode0)))
  end
  local function on_finish()
    local op_canceled_3f = false
    local ns_id
    local function _7_(key, typed)
      if cancels_3f(key) then
        op_canceled_3f = true
        return nil
      else
        return nil
      end
    end
    ns_id = vim.on_key(_7_)
    local callback
    local function _9_()
      restore_cursor()
      vim.on_key(nil, ns_id)
      if not op_canceled_3f then
        return api.nvim_exec_autocmds("User", {pattern = "RemoteOperationDone", data = state})
      else
        return nil
      end
    end
    callback = vim.schedule_wrap(_9_)
    local function _11_()
      local mode0 = vim.fn.mode(true)
      if (mode0:match("o") and (vim.v.operator == "c")) then
        return api.nvim_create_autocmd("ModeChanged", {pattern = "i:n", once = true, callback = callback})
      else
        return api.nvim_create_autocmd("ModeChanged", {pattern = "*:n", once = true, callback = callback})
      end
    end
    return api.nvim_create_autocmd("ModeChanged", {pattern = "*:*", once = true, callback = _11_})
  end
  to_normal_mode()
  local function _13_()
    local function after_jump()
      if cursor_moved_3f() then
        vim.cmd("norm! m`")
        back_to_pending_action()
        if input then
          api.nvim_feedkeys(input, "", false)
        else
        end
        return vim.schedule(on_finish)
      else
        return nil
      end
    end
    if (type(jumper0) == "string") then
      api.nvim_feedkeys(jumper0, "n", false)
    else
      jumper0()
    end
    local function _17_()
      if (type(jumper0) == "string") then
        return api.nvim_create_autocmd("CmdlineLeave", {once = true, callback = vim.schedule_wrap(after_jump)})
      else
        return after_jump()
      end
    end
    return vim.schedule(_17_)
  end
  return vim.schedule(_13_)
end
return {action = action}
