---@module 'mdn.checkbox'

local Config = require("mdn.config")
local List = require("mdn.list")
local M = {}

---Three-state cycle: blank → bullet → checkbox → toggle.
---
---State 1: Blank or non-list line → insert bullet marker
---State 2: List item without checkbox → add "[ ] " after marker
---State 3: Checkbox present → toggle [ ] ↔ [x]
---
---Uses Config.lists.bullet_marker for the bullet character (default: "-").
---Works in both Normal and Insert mode.
function M.cycle()
  local lnum = vim.fn.line(".")
  local line = vim.api.nvim_get_current_line()
  local marker = Config.lists.bullet_marker .. " "

  -- State 1: Blank or non-list line → create bullet point
  local lcontent = List.resolve_list_content(line)
  if not lcontent then
    if line:match("^%s*$") then
      -- Blank line: replace with marker
      vim.api.nvim_set_current_line(marker)
    else
      -- Non-blank non-list: prepend marker to turn it into a bullet
      vim.api.nvim_set_current_line(marker .. line)
    end
    vim.fn.cursor(lnum, #marker + 1)
    return
  end

  local task_state = List.get_task_state(lcontent.text)
  local cursor_col = vim.fn.col(".")

  if task_state then
    -- State 3: Toggle checkbox [ ] ↔ [x], or complete [~] → [x]
    if task_state == "unchecked" or task_state == "in_progress" then
      local new_line = line:gsub("%[([~ xX])%]", "[x]", 1)
      vim.api.nvim_set_current_line(new_line)
    else
      local new_line = line:gsub("%[[xX]%]", "[ ]", 1)
      vim.api.nvim_set_current_line(new_line)
    end
    vim.fn.cursor(lnum, cursor_col)
  else
    -- State 2: Bullet exists, no checkbox → add [ ] after marker
    local marker_with_sep = lcontent.marker .. lcontent.separator
    local escaped_marker = marker_with_sep:gsub("%p", "%%%1")
    local new_line = line:gsub(escaped_marker .. "%s*", marker_with_sep .. " [ ] ", 1)
    vim.api.nvim_set_current_line(new_line)
    vim.fn.cursor(lnum, cursor_col + 4)
  end
end

---Toggle only the checkbox state (no bullet creation).
---Used by the :Mdn toggle command.
---Returns true if toggled, false if no checkbox was found.
---@return boolean
function M.toggle()
  local line = vim.api.nvim_get_current_line()
  local lcontent = List.resolve_list_content(line)
  if not lcontent then
    return false
  end

  local task_state = List.get_task_state(lcontent.text)
  if not task_state then
    -- No checkbox — add [ ] after marker (same as cycle state 2)
    local lnum = vim.fn.line(".")
    local cursor_col = vim.fn.col(".")
    local marker_with_sep = lcontent.marker .. lcontent.separator
    local escaped_marker = marker_with_sep:gsub("%p", "%%%1")
    local new_line = line:gsub(escaped_marker .. "%s*", marker_with_sep .. " [ ] ", 1)
    vim.api.nvim_set_current_line(new_line)
    vim.fn.cursor(lnum, cursor_col + 4)
    return true
  end

  -- Toggle existing checkbox
  local lnum = vim.fn.line(".")
  local cursor_col = vim.fn.col(".")
  if task_state == "unchecked" or task_state == "in_progress" then
    vim.api.nvim_set_current_line((line:gsub("%[([~ xX])%]", "[x]", 1)))
  else
    vim.api.nvim_set_current_line((line:gsub("%[[xX]%]", "[ ]", 1)))
  end
  vim.fn.cursor(lnum, cursor_col)
  return true
end

return M
