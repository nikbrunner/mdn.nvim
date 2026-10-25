---@module 'mdn.syntax'

local M = {}

local code_query_text = [[
[
  (fenced_code_block)
  (indented_code_block)
  (html_block)
] @code
]]

---@type vim.treesitter.Query?
local code_query

---Parse the buffer and return the root of its Markdown tree.
---Parsing on every call keeps the tree current in Insert mode, where it
---would otherwise lag one keystroke behind.
---@param buf integer Buffer id
---@return TSNode?
function M.tree(buf)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  -- Asking for a different language replaces the buffer's cached parser.
  local filetype = vim.bo[buf].filetype
  if filetype ~= "" and filetype ~= "markdown" then
    return nil
  end
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown", { error = false })
  if not ok or not parser then
    return nil
  end
  local parse_ok, trees = pcall(parser.parse, parser)
  if not parse_ok or not trees or not trees[1] then
    return nil
  end
  return trees[1]:root()
end

---Whether the Markdown parser can be used for the buffer.
---@param buf integer Buffer id
---@return boolean
function M.available(buf)
  return M.tree(buf) ~= nil
end

---Rows inside code and HTML blocks, as a set of 0-indexed rows.
---Empty without a parser.
---@param buf integer Buffer id
---@return table<integer, true>
function M.code_rows(buf)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local root = M.tree(buf)
  if not root then
    return {}
  end
  if not code_query then
    code_query = vim.treesitter.query.parse("markdown", code_query_text)
  end

  local rows = {}
  for _, node in code_query:iter_captures(root, buf, 0, -1) do
    local start_row, _, end_row, end_col = node:range()
    if end_col == 0 then
      end_row = end_row - 1
    end
    for row = start_row, end_row do
      rows[row] = true
    end
  end
  return rows
end

---Whether a row lies inside a code or HTML block. False without a parser.
---@param buf integer Buffer id
---@param row integer 0-indexed row
---@return boolean
function M.in_code(buf, row)
  return M.code_rows(buf)[row] == true
end

return M
