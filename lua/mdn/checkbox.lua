---@module 'mdn.checkbox'

local Config = require("mdn.config")
local List = require("mdn.list")
local M = {}

---Four-state cycle: blank → bullet → unchecked → in-progress → done → ...
---
---State 1: Blank or non-list line → insert bullet marker
---State 2: List item without checkbox → add "[ ] " after marker
---State 3: Checkbox present:
---  [ ]  → [~] (unchecked → in progress)
---  [~]  → [x] (in progress → done)
---  [x]  → [ ] (done → unchecked, cycle restarts)
---  other → [x] (complete non-standard checkbox)
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
    -- State 3: Cycle through checkbox states
    -- [ ] → [~] → [x] → [ ] (continuous cycle)
    -- Other checkbox chars → [x] (complete to done)
    local cb_char = lcontent.text:match("^%[(.)%]")
    if cb_char == " " then
      -- [ ] → [~] (unchecked → in progress)
      local new_line = line:gsub("%[ %]", "[~]", 1)
      vim.api.nvim_set_current_line(new_line)
    elseif cb_char == "~" then
      -- [~] → [x] (in progress → done)
      local new_line = line:gsub("%[~%]", "[x]", 1)
      vim.api.nvim_set_current_line(new_line)
    elseif cb_char == "x" or cb_char == "X" then
      -- [x] → [ ] (done → unchecked, restart cycle)
      local new_line = line:gsub("%[[xX]%]", "[ ]", 1)
      vim.api.nvim_set_current_line(new_line)
    else
      -- Other checkbox chars → [x] (complete to done)
      local new_line = line:gsub("%[(.)%]", "[x]", 1)
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
  if task_state == "unchecked" or task_state == "other" then
    vim.api.nvim_set_current_line((line:gsub("%[(.)%]", "[x]", 1)))
  else
    vim.api.nvim_set_current_line((line:gsub("%[[xX]%]", "[ ]", 1)))
  end
  vim.fn.cursor(lnum, cursor_col)
  return true
end

return M
