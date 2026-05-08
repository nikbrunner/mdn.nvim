---@module 'mdn.checkbox'

local List = require("mdn.list")
local M = {}

---Toggle the checkbox on the current line.
---Handles all three cases:
---  1. [ ] → [x] (check the box)
---  2. [x] → [ ] (uncheck the box)
---  3. No checkbox present, but it's a list item → adds [ ] after the marker
---Returns true if a toggle was performed, false if the line is not a list item.
---@return boolean toggled
function M.toggle()
  local lnum = vim.fn.line(".")
  local line = vim.api.nvim_get_current_line()
  local lcontent = List.resolve_list_content(line)

  if not lcontent then
    return false
  end

  local task_state = List.get_task_state(lcontent.text)
  local cursor_col = vim.fn.col(".")

  if task_state == "unchecked" then
    -- [ ] → [x]
    local new_line = line:gsub("%[ %]", "[x]", 1)
    vim.api.nvim_set_current_line(new_line)
    -- Cursor changes by 1 (space → x), ie stays in same relative position
    vim.fn.cursor(lnum, cursor_col)
  elseif task_state == "checked" then
    -- [x] → [ ]
    local new_line = line:gsub("%[[xX]%]", "[ ]", 1)
    vim.api.nvim_set_current_line(new_line)
    vim.fn.cursor(lnum, cursor_col)
  else
    -- No checkbox — add [ ] after the marker
    local marker_with_sep = lcontent.marker .. lcontent.separator
    -- Escape any special characters for gsub
    local escaped_marker = marker_with_sep:gsub("%p", "%%%1")
    local new_line = line:gsub(escaped_marker .. "%s*", marker_with_sep .. " [ ] ", 1)
    vim.api.nvim_set_current_line(new_line)
    -- Cursor moves right by 4 (the added " [ ] ")
    vim.fn.cursor(lnum, cursor_col + 4)
  end

  return true
end

---Get the expression result for <Plug> mapping in Insert mode.
---Returns the key sequence to send (or empty string if not a list item).
---@return string
function M.toggle_expr()
  local line = vim.api.nvim_get_current_line()
  local lcontent = List.resolve_list_content(line)

  if not lcontent then
    return ""
  end

  -- In insert mode, we need to manipulate the line and reposition cursor
  local task_state = List.get_task_state(lcontent.text)
  local cur_col = vim.fn.col(".")

  if task_state == "unchecked" then
    -- [ ] → [x]: replace space with x
    -- Find position of the [ in the checkbox
    local checkbox_start = lcontent.indent:len() + lcontent.marker:len() + lcontent.separator:len() + 2
    local new_line = line:gsub("%[ %]", "[x]", 1)
    vim.api.nvim_set_current_line(new_line)
    vim.fn.cursor(vim.fn.line("."), cur_col)
    return ""
  elseif task_state == "checked" then
    -- [x] → [ ]
    local new_line = line:gsub("%[[xX]%]", "[ ]", 1)
    vim.api.nvim_set_current_line(new_line)
    vim.fn.cursor(vim.fn.line("."), cur_col)
    return ""
  else
    -- Add [ ] after marker
    local marker_with_sep = lcontent.marker .. lcontent.separator
    local escaped_marker = marker_with_sep:gsub("%p", "%%%1")
    local new_line = line:gsub(escaped_marker .. "%s*", marker_with_sep .. " [ ] ", 1)
    vim.api.nvim_set_current_line(new_line)
    vim.fn.cursor(vim.fn.line("."), cur_col + 4)
    return ""
  end
end

return M
