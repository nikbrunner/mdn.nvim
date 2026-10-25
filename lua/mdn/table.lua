---@module 'mdn.table'

local Syntax = require("mdn.syntax")
local M = {}

---@class MdnTableCell
---@field text string Cell content without surrounding whitespace
---@field first integer 0-indexed byte offset where the cell's segment starts
---@field last integer 0-indexed byte offset where the cell's segment ends
---@field content integer 0-indexed byte offset where `text` starts

---Split a table row into cells on every `|` not escaped with `\`.
---Outer pipes are optional, as in GFM.
---@param text string Row text, starting where the table starts
---@return MdnTableCell[]
local function split_row(text)
  local cells = {}
  local start = 0
  local i = 1
  local function push(stop)
    local segment = text:sub(start + 1, stop)
    local lead = #segment:match("^%s*")
    table.insert(cells, { text = vim.trim(segment), first = start, last = stop, content = start + lead })
  end
  while i <= #text do
    local char = text:sub(i, i)
    if char == "\\" then
      i = i + 2
    else
      if char == "|" then
        push(i - 1)
        start = i
      end
      i = i + 1
    end
  end
  push(#text)

  if #cells > 1 and text:match("^%s*|") then
    table.remove(cells, 1)
  end
  if #cells > 1 and cells[#cells].text == "" then
    table.remove(cells)
  end
  return cells
end

---@param root TSNode
---@param buf integer
---@param row integer
---@return TSNode?
local function table_at(root, buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local col = math.max(#line:gsub("%s+$", "") - 1, 0)
  local node = root:named_descendant_for_range(row, col, row, col)
  while node do
    if node:type() == "pipe_table" then
      return node
    end
    node = node:parent()
  end
end

---Pad the cells of the table around a row so its columns line up in the
---source. Short rows get empty cells; no text is removed. Does nothing
---outside a table or without a parser.
---@param buf integer Buffer id
---@param row integer 0-indexed row
---@return boolean changed
function M.fit(buf, row)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local root = Syntax.tree(buf)
  local tbl = root and table_at(root, buf, row)
  if not tbl then
    return false
  end

  local rows = {}
  for child in tbl:iter_children() do
    local child_row, col = child:range()
    if child:named() and child:type():match("^pipe_table_") then
      local line = vim.api.nvim_buf_get_lines(buf, child_row, child_row + 1, false)[1]
      table.insert(rows, {
        row = child_row,
        line = line,
        prefix = line:sub(1, col),
        cells = split_row(line:sub(col + 1)),
        delimiter = child:type() == "pipe_table_delimiter_row",
      })
    end
  end

  local columns = #rows[1].cells
  local widths = {}
  for _, r in ipairs(rows) do
    for _ = #r.cells + 1, columns do
      table.insert(r.cells, { text = "" })
    end
    for i, cell in ipairs(r.cells) do
      local width = r.delimiter and 3 or vim.fn.strdisplaywidth(cell.text)
      widths[i] = math.max(widths[i] or 0, width)
    end
  end

  local cursor
  if vim.api.nvim_get_current_buf() == buf then
    cursor = vim.api.nvim_win_get_cursor(0)
  end

  local changed = false
  for _, r in ipairs(rows) do
    local parts = {}
    local starts = {}
    local offset = #r.prefix + 2
    for i, cell in ipairs(r.cells) do
      local text = cell.text
      if r.delimiter then
        local left = text:sub(1, 1) == ":" and ":" or ""
        local right = #text > 1 and text:sub(-1) == ":" and ":" or ""
        text = left .. ("-"):rep(widths[i] - #left - #right) .. right
      else
        text = text .. (" "):rep(widths[i] - vim.fn.strdisplaywidth(text))
      end
      starts[i] = offset
      offset = offset + #text + 3
      table.insert(parts, text)
    end
    local new_line = r.prefix .. "| " .. table.concat(parts, " | ") .. " |"

    if new_line ~= r.line then
      vim.api.nvim_buf_set_lines(buf, r.row, r.row + 1, false, { new_line })
      changed = true
      if cursor and cursor[1] - 1 == r.row then
        local col = cursor[2] - #r.prefix
        for i, cell in ipairs(r.cells) do
          if cell.first and col >= cell.first and col <= cell.last then
            local inside = math.min(math.max(col - cell.content, 0), #cell.text)
            vim.api.nvim_win_set_cursor(0, { cursor[1], starts[i] + inside })
            break
          end
        end
      end
    end
  end
  return changed
end

return M
