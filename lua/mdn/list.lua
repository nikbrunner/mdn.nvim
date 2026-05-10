---@module 'mdn.list'

local P = require("mdn.patterns")
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
---Returns the current checkbox state: "unchecked", "checked", or nil if no checkbox.
---@param text string The text portion of a list item
---@return string? state "unchecked"|"checked"|nil
function M.get_task_state(text)
  if text:match("^%[ %]") then
    return "unchecked"
  elseif text:match("^%[[xX]%]") then
    return "checked"
  end
  return nil
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
  local lcontent = M.resolve_list_content(line)

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

return M
