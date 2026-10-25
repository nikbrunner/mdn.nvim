---@module 'mdn.list'

local P = require("mdn.patterns")
local Syntax = require("mdn.syntax")
local M = {}

---@class MdnListContent
---@field indent string Indent whitespace before the marker
---@field marker string List item marker (e.g. "-", "*", "+", "1")
---@field separator string Separator for ordered lists (e.g. ".", ")"), empty for unordered
---@field text string Text after the marker/separator
---@field type '"ordered"'|'"unordered"' Type of list

---Parse a line into structured list content.
---Returns nil if the line is not a list item.
---@param line string
---@return MdnListContent?
function M.resolve_list_content(line)
  vim.validate("line", line, "string")

  -- Try ordered list first
  local ol_indent, ol_marker, ol_separator, ol_text = line:match(P.ordered_list)
  if ol_indent and ol_marker and ol_separator then
    return {
      indent = ol_indent,
      marker = ol_marker,
      separator = ol_separator,
      text = ol_text or "",
      type = "ordered",
    }
  end

  -- Try unordered list
  local ul_indent, ul_marker, ul_text = line:match(P.unordered_list)
  if ul_indent and ul_marker then
    return {
      indent = ul_indent,
      marker = ul_marker,
      separator = "",
      text = ul_text or "",
      type = "unordered",
    }
  end

  return nil
end

---Check if the text portion of a list item has a task checkbox.
---Recognizes any single character inside brackets at the start of text
---as a task state: "[ ]" is unchecked, "[x]"/"[X]" is checked, all
---other variants ("[~]", "[>]", "[o]", "[<]", etc.) are "other".
---Returns nil if no checkbox is present.
---@param text string The text portion of a list item
---@return string? state "unchecked"|"checked"|"other"|nil
function M.get_task_state(text)
  local char = text:match("^%[(.)%]")
  if not char then
    return nil
  end
  if char == " " then
    return "unchecked"
  elseif char == "x" or char == "X" then
    return "checked"
  end
  return "other"
end

---Generate the continuation prefix for the next list item.
---For ordered lists, increments the number.
---For task items, preserves the empty checkbox.
---Returns nil if the current line text is empty (signaling no continuation).
---@param lcontent MdnListContent The parsed content of the current line
---@return string? prefix The prefix for the next line (e.g. "- ", "2. ", "- [ ] ")
function M.get_continuation_prefix(lcontent)
  -- Don't continue if text is empty (user just has "- " with nothing after)
  if lcontent.text == "" then
    return nil
  end

  local text_without_task = lcontent.text
  local task_state = M.get_task_state(lcontent.text)

  -- Strip task checkbox from text for the check
  if task_state then
    text_without_task = lcontent.text:gsub("^%[.%]%s*", "")
    if text_without_task == "" then
      return nil -- Empty task item: "- [ ]" terminates continuation
    end
  end

  if lcontent.type == "ordered" then
    local next_number = tonumber(lcontent.marker) + 1
    if task_state then
      return lcontent.indent .. tostring(next_number) .. lcontent.separator .. " [ ] "
    else
      return lcontent.indent .. tostring(next_number) .. lcontent.separator .. " "
    end
  end

  -- Unordered
  if task_state then
    return lcontent.indent .. lcontent.marker .. " [ ] "
  else
    return lcontent.indent .. lcontent.marker .. " "
  end
end

---Get the previous line prefix (for O key — insert above).
---For ordered lists, decrements the number but never goes below 1.
---@param lcontent MdnListContent
---@return string? prefix
function M.get_previous_prefix(lcontent)
  -- Don't continue if text is empty
  if lcontent.text == "" then
    return nil
  end

  local text_without_task = lcontent.text
  local task_state = M.get_task_state(lcontent.text)

  if task_state then
    text_without_task = lcontent.text:gsub("^%[.%]%s*", "")
    if text_without_task == "" then
      return nil
    end
  end

  if lcontent.type == "ordered" then
    local prev_number = math.max(1, tonumber(lcontent.marker) - 1)
    if task_state then
      return lcontent.indent .. tostring(prev_number) .. lcontent.separator .. " [ ] "
    else
      return lcontent.indent .. tostring(prev_number) .. lcontent.separator .. " "
    end
  end

  -- Unordered — same marker as current
  if task_state then
    return lcontent.indent .. lcontent.marker .. " [ ] "
  else
    return lcontent.indent .. lcontent.marker .. " "
  end
end

---Calculate the 1-indexed column where user text starts after the list prefix.
---For "- item" returns 3 (past "- "), for "- [ ] item" returns 7 (past "- [ ] ").
---@param lcontent MdnListContent
---@return integer
local function get_content_start_col(lcontent)
  local len = #lcontent.indent + #lcontent.marker + 1 -- indent + marker + space
  if lcontent.separator ~= "" then
    len = len + #lcontent.separator -- ordered list separator
  end
  -- Check if text has a checkbox prefix
  local task_state = M.get_task_state(lcontent.text)
  if task_state then
    len = len + 4 -- "[ ] " or "[x] "
  end
  return len + 1
end

---Insert a new list item below or above the current line.
---@param key '"o"'|'"O"'|'"<CR>"' Which key triggered the continuation
function M.continue(key)
  vim.validate("key", key, "string")

  local lnum = vim.fn.line(".")
  local line = vim.api.nvim_get_current_line()
  local lcontent
  if not Syntax.in_code(0, lnum - 1) then
    lcontent = M.resolve_list_content(line)
  end

  if not lcontent then
    -- Not a list item — do normal behavior
    if key == "<CR>" then
      -- In Insert mode, feedkeys("<CR>") inserts literal text.
      -- Instead, split the line at cursor to simulate a newline.
      local col = vim.fn.col(".")
      local before = line:sub(1, col - 1)
      local after = line:sub(col)
      vim.api.nvim_set_current_line(before)
      vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { after })
      vim.fn.cursor(lnum + 1, 1)
    elseif key == "o" then
      vim.api.nvim_feedkeys("o", "n", false)
    elseif key == "O" then
      vim.api.nvim_feedkeys("O", "n", false)
    end
    return
  end

  local prefix
  if key == "o" or key == "<CR>" then
    prefix = M.get_continuation_prefix(lcontent)
  elseif key == "O" then
    prefix = M.get_previous_prefix(lcontent)
  end

  -- When <CR> fires from Insert mode, we're already in insert mode —
  -- don't feed "a" or we'll type a literal "a" on the new line.
  -- o/O fires from Normal mode, so we need to enter insert mode.
  local is_insert = (key == "<CR>")

  if not prefix then
    -- No continuation — clear the empty list item (exit the list)
    if key == "o" or key == "<CR>" then
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { "" })
      vim.fn.cursor(lnum, 1)
    elseif key == "O" then
      -- Clear the empty item then insert blank above
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { "" })
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum - 1, false, { "" })
      vim.fn.cursor(lnum, 1)
    end
    if not is_insert then
      vim.api.nvim_feedkeys("a", "n", false)
    end
    return
  end

  if key == "o" or key == "<CR>" then
    -- For <CR> in insert mode: if cursor is past the list prefix area,
    -- split the line at cursor and continue with the trailing text.
    -- If cursor is at the end or within the prefix, create empty continuation.
    if key == "<CR>" then
      local col = vim.fn.col(".")
      local content_start = get_content_start_col(lcontent)
      if col >= content_start then
        local after = line:sub(col)
        if after ~= "" then
          -- Split: keep left of cursor on current line,
          -- insert prefix + text after cursor on new line
          local before = line:sub(1, col - 1)
          vim.api.nvim_set_current_line(before)
          vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { prefix .. after })
          vim.fn.cursor(lnum + 1, #prefix + 1)
        else
          -- At end of line: create empty continuation
          vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { prefix })
          vim.fn.cursor(lnum + 1, #prefix + 1)
        end
      else
        -- Within the marker/checkbox area: create empty continuation
        vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { prefix })
        vim.fn.cursor(lnum + 1, #prefix + 1)
      end
    else
      -- o from Normal mode: always create empty continuation below
      vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { prefix })
      vim.fn.cursor(lnum + 1, #prefix + 1)
    end
  elseif key == "O" then
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum - 1, false, { prefix })
    vim.fn.cursor(lnum, #prefix + 1)
  end

  if not is_insert then
    vim.api.nvim_feedkeys("a", "n", false)
  end
end

local ordered_markers = {
  list_marker_dot = true,
  list_marker_parenthesis = true,
}

---Shift the continuation rows of a list item by `delta` columns at `col`,
---so nested content stays nested when its marker changes width.
---@param buf integer
---@param first_row integer 0-indexed first continuation row
---@param last_row integer 0-indexed last continuation row
---@param col integer 0-indexed column where the item's marker starts
---@param width integer Width of the marker before the change
---@param delta integer Columns to add (positive) or remove (negative)
local function shift_continuation(buf, first_row, last_row, col, width, delta)
  for row = first_row, last_row do
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    if line:sub(col + 1, col + width):match("^ +$") then
      if delta > 0 then
        vim.api.nvim_buf_set_text(buf, row, col, row, col, { (" "):rep(delta) })
      elseif line:sub(col + 1, col - delta):match("^ +$") then
        vim.api.nvim_buf_set_text(buf, row, col, row, col - delta, { "" })
      end
    end
  end
end

---Number the items of one ordered list from 1.
---@param buf integer
---@param list TSNode A `list` node
---@return boolean changed
local function renumber_list(buf, list)
  local number = 0
  local changed = false
  for item in list:iter_children() do
    local marker = item:type() == "list_item" and item:named_child(0)
    if marker then
      if not ordered_markers[marker:type()] then
        return changed
      end
      number = number + 1
      local row, col, _, marker_end = marker:range()
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
      local digits = line:sub(col + 1, marker_end):match("^%d+")
      local wanted = tostring(number)
      if digits and digits ~= wanted then
        vim.api.nvim_buf_set_text(buf, row, col, row, col + #digits, { wanted })
        changed = true
        local delta = #wanted - #digits
        if delta ~= 0 then
          local _, _, end_row, end_col = item:range()
          local last_row = end_col == 0 and end_row - 1 or end_row
          shift_continuation(buf, row + 1, last_row, col, marker_end - col, delta)
        end
      end
    end
  end
  return changed
end

---Find the `depth`-th enclosing `list` node of a row, innermost first.
---@param root TSNode
---@param buf integer
---@param row integer 0-indexed row
---@param depth integer
---@return TSNode?
local function enclosing_list(root, buf, row, depth)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local col = math.max((line:find("%S") or 1) - 1, 0)
  local node = root:named_descendant_for_range(row, col, row, col)
  local found = 0
  while node do
    if node:type() == "list" then
      found = found + 1
      if found == depth then
        return node
      end
    end
    node = node:parent()
  end
end

---Number every ordered list around a row from 1, innermost list first.
---Unordered lists are left alone. Does nothing without a parser.
---@param buf integer Buffer id
---@param row integer 0-indexed row
---@return boolean changed
function M.renumber(buf, row)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local changed = false
  local depth = 1
  while true do
    local root = Syntax.tree(buf)
    local list = root and enclosing_list(root, buf, row, depth)
    if not list then
      return changed
    end
    changed = renumber_list(buf, list) or changed
    depth = depth + 1
  end
end

return M
